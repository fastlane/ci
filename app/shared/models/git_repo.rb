# We're using https://github.com/ruby-git/ruby-git
# for all git interactions
require "git"
require "tty-command"
require "securerandom"
require "digest"
require "task_queue"
require "faraday-http-cache"

require_relative "../logging_module"

require_relative "../git_monkey_patches"

module FastlaneCI
  # Encapsulates all the data that is needed by GitRepo
  # We can have various provider_credentials, but they all need to be turned into `GitRepoAuth`s
  # This is because different git providers can have different needs for data
  # What github needs is an `api_token`, but a local git repo might only need a `password`.
  # We'll call both of these "auth_tokens" here, this way we can use GitRepoAuth
  # as a way to unify those, and prevent overloading names at the data source.
  # Otherwise, in the JSON we'd see "password" but for some repos that might be an auth_token, or an api_token, or password
  class GitRepoAuth
    attr_accessor :remote_host # in the case of github, this is usually `github.com`
    attr_accessor :username    # whatever the git repo needs for a username, usually just an email, usually CI
    attr_accessor :full_name   # whatever the git repo needs for a username, usually just an email, usually fastlane.CI
    attr_accessor :auth_token  # usually an API key, but could be a password, usually fastlane.CI's auth_token
    def initialize(remote_host: nil, username: nil, full_name: nil, auth_token: nil)
      @remote_host = remote_host
      @username = username
      @full_name = full_name
      @auth_token = auth_token
    end
  end

  # Responsible for managing git repos
  # This includes the configs repo, but also the actual source code repos
  # This class makes sure to use the right credentials, does proper cloning,
  # pulling, pushing, git commit messages, etc.
  # It is **important** that from the outside you don't access `GitRepoObject.git.something` directly
  # as the auth won't be setup. This system is designed to authenticate the user per action, meaning
  # that each pull, push, fetch etc. is performed using a specific user
  class GitRepo
    include FastlaneCI::Logging

    # @return [GitRepoConfig]
    attr_accessor :git_config
    # @return [GitRepoAuth]
    attr_accessor :repo_auth # whatever pieces of information that can change between git users

    attr_accessor :temporary_storage_path

    attr_reader :local_folder # where we are keeping the local repo checkout

    # This callback is used when the instance is initialized in async mode, so you can define a proc
    # with the final GitRepo configured.
    #   @example
    #   GitRepo.new(..., async_start: true, callback: proc { |repo| puts "This is my final repo #{repo}"; })
    #
    # @return [proc(GitRepo)]
    attr_accessor :callback

    class << self
      attr_accessor :git_action_queue

      # Loads the octokit cache stack for speed-up calls to github service.
      # As explained in: https://github.com/octokit/octokit.rb#caching
      def load_octokit_cache_stack
        @stack ||= Faraday::RackBuilder.new do |builder|
          builder.use(Faraday::HttpCache, serializer: Marshal, shared_cache: false)
          builder.use(Octokit::Response::RaiseError)
          builder.adapter(Faraday.default_adapter)
        end
        return if Octokit.middleware.handlers.include?(Faraday::HttpCache)
        Octokit.middleware = @stack
      end
    end

    GitRepo.git_action_queue = TaskQueue::TaskQueue.new(name: "GitRepo task queue")

    # Initializer for GitRepo class
    # @param git_config [GitConfig]
    # @param provider_credential [ProviderCredential]
    # @param async_start [Bool] Whether the repo should be setup async or not. (Defaults to `true`)
    # @param sync_setup_timeout_seconds [Integer] When in sync setup mode, how many seconds to wait until raise an exception. (Defaults to 300)
    # @param callback [proc(GitRepo)] When in async setup mode, the proc to be called with the final GitRepo setup.
    def initialize(git_config: nil, local_folder: nil, provider_credential: nil, async_start: false, sync_setup_timeout_seconds: 300, callback: nil)
      GitRepo.load_octokit_cache_stack
      logger.debug("Creating repo in #{local_folder} for a copy of #{git_config.git_url}")
      self.validate_initialization_params!(git_config: git_config, local_folder: local_folder, provider_credential: provider_credential, async_start: async_start, callback: callback)
      @git_config = git_config
      @local_folder = local_folder
      @callback = callback

      # Ok, so now we need to pull the bit of information from the credentials that we know we need for git repos
      case provider_credential.type
      when FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
        # Package up the authentication parts that are required
        @repo_auth = GitRepoAuth.new(
          remote_host: provider_credential.remote_host,
          username: provider_credential.email,
          full_name: provider_credential.full_name,
          auth_token: provider_credential.api_token
        )
      else
        # if we add another ProviderCredential type, we'll need to figure out what parts of the credential go where
        raise "unsupported credential type: #{provider_credential.type}"
      end

      logger.debug("Adding task to setup repo #{self.git_config.git_url} at: #{local_folder}")

      setup_task = git_action_with_queue(ensure_block: proc { callback_block(async_start) }) do
        logger.debug("Starting setup_repo #{self.git_config.git_url}".freeze)
        self.setup_repo
        logger.debug("Done setup_repo #{self.git_config.git_url}".freeze)
      end

      # if we're starting asynchronously, we can return now.
      if async_start
        logger.debug("Asynchronously starting up repo: #{self.git_config.git_url}")
        return
      end

      logger.debug("Synchronously starting up repo: #{self.git_config.git_url}")
      now = Time.now.utc
      sleep_timeout = now + sync_setup_timeout_seconds # 10 second startup timeout
      while !setup_task.completed && now < sleep_timeout
        time_left = sleep_timeout - now
        logger.debug("Not setup yet, sleeping (time before timeout: #{time_left}) #{self.git_config.git_url}")
        sleep(2)
        now = Time.now.utc
      end

      raise "Unable to start git repo #{git_config.git_url} in #{sync_setup_timeout_seconds} seconds" if now > sleep_timeout
      logger.debug("Done starting up repo: #{self.git_config.git_url}")
    end

    def setup_repo
      retry_count ||= 0
      if File.directory?(self.local_folder)
        # TODO: test if this crashes if it's not a git directory
        begin
          @_git = Git.open(self.local_folder)
        rescue ArgumentError => aex
          logger.debug("Path #{self.local_folder} is not a git directory, deleting and trying again")
          self.clear_directory
          self.clone
          retry if (retry_count += 1) < 5
          raise "Exceeded retry count for #{__method__}. Exception: #{aex}"
        end
        repo = self.git
        if repo.index.writable?
          # Things are looking legit so far
          # Now we have to check if the repo is actually from the
          # same repo URL
          if repo.remote("origin").url.casecmp(self.git_config.git_url.downcase).zero?
            # If our courrent repo is the ci-config repo and has changes on it, we should commit them before
            # other actions, to prevent local changes to be lost.
            # This is a common issue, ci_config repo gets recreated several times trough the Services.configuration_git_repo
            # and if some changes in the local repo (added projects, etc.) have been added, they're destroyed.
            # rubocop:disable Metrics/BlockNesting
            if self.local_folder == File.expand_path("~/.fastlane/ci/fastlane-ci-config")
              # TODO: move this stuff out of here
              # TODO: In case there are conflicts with remote, we want to decide which way we take.
              # For now, we merge using the 'recursive' strategy.
              if !repo.status.changed == 0 && !repo.status.added == 0 && !repo.status.deleted == 0 && !repo.status.untracked == 0
                begin
                  repo.add(all: true)
                  repo.commit("Sync changes")
                  git.push("origin", branch: "master", force: true)
                rescue StandardError => ex
                  logger.error("Error commiting changes to ci-config repo")
                  logger.error(ex)
                end
              end
            else
              logger.debug("Resetting #{self.git_config.git_url} in setup_repo")
              self.git.reset_hard
              logger.debug("Ensuring we're on `master` for #{self.git_config.git_url} in setup_repo")
              git.branch("master").checkout
              logger.debug("Resetting `master` #{self.git_config.git_url} in setup_repo")
              self.git.reset_hard

              logger.debug("Pulling `master` #{self.git_config.git_url} in setup_repo")
              self.pull
            end
          else
            logger.debug("[#{self.git_config.id}] Repo URL seems to have changed... deleting the old directory and cloning again")
            self.clear_directory
            self.clone
          end
        else
          self.clear_directory
          logger.debug("Cloning #{self.git_config.git_url} into #{self.local_folder} after clearing directory")
          self.clone
        end
      else
        logger.debug("Cloning #{self.git_config.git_url} into #{self.local_folder}")
        self.clone

        # now that we've cloned, we can setup the @_git variable
        @_git = Git.open(self.local_folder)
      end
      logger.debug("Done, now using #{self.local_folder} for #{self.git_config.git_url}")
      # rubocop:enable Metrics/BlockNesting
    end

    def validate_initialization_params!(git_config: nil, local_folder: nil, provider_credential: nil, async_start: nil, callback: nil)
      raise "No git config provided" if git_config.nil?
      raise "No local_folder provided" if local_folder.nil?
      raise "No provider_credential provided" if provider_credential.nil?
      raise "Callback provided but not initialized in async mode" if !callback.nil? && !async_start

      credential_type = provider_credential.type
      git_config_credential_type = git_config.provider_credential_type_needed

      credential_mismatch = credential_type != git_config_credential_type
      raise "provider_credential.type and git_config.provider_credential_type_needed mismatch: #{credential_type} vs #{git_config_credential_type}" if credential_mismatch
    end

    def clear_directory
      logger.debug("Deleting #{self.local_folder}")
      FileUtils.rm_rf(self.local_folder)
    end

    # Returns the absolute path to a file from inside the git repo
    def file_path(file_path)
      File.join(self.local_folder, file_path)
    end

    def git
      return @_git
    end

    # call like you would self.git.branches.remote.each { |branch| branch.yolo }
    # call like you would, but you also get the git repo involved, so it's  .each { |git, branch| branch.yolo; git.yolo }
    def git_and_remote_branches_each(&each_block)
      git_action_with_queue do
        branch_count = 0
        self.git.branches.remote.each do |branch|
          each_block.call(self.git, branch)
          branch_count += 1
        end
      end
    end

    # Return the last commit, that isn't a merge commit
    # Make sure to have checked out the right branch for which
    # you want to get the last commit of
    def most_recent_commit
      self.git.log.each do |commit|
        # 2 parents only happen on merge commits https://stackoverflow.com/a/3824122
        return commit unless commit.parents.count >= 2
      end
      return nil
    end

    # Responsible for setting the author information when committing a change
    # NOT PROTECTED BY QUEUE, ONLY CALL WHEN INSIDE A git_action_queue BLOCK
    def setup_author(full_name: self.repo_auth.full_name, username: self.repo_auth.username)
      # TODO: performance implications of settings this every time?
      # TODO: Set actual name + email here
      # TODO: see if we can set credentials here also
      if full_name.nil? || full_name.length == 0
        full_name = "Unknown user"
      end
      logger.debug("Using #{full_name} with #{username} as author information on #{self.git_config.git_url}")
      git.config("user.name", full_name)
      git.config("user.email", username)
    end

    def temporary_git_storage
      @temporary_git_storage ||= File.expand_path("~/.fastlane/.tmp")
      FileUtils.mkdir_p(@temporary_git_storage)
      return @temporary_git_storage
    end

    # Responsible for using the auth token to be able to push/pull changes
    # from git remote
    def setup_auth(repo_auth: self.repo_auth)
      # generate a unique file name for this specific user, host, and git url
      git_auth_key = Digest::SHA2.hexdigest(repo_auth.remote_host + repo_auth.username + self.git_config.git_url)
      temporary_storage_path = File.join(self.temporary_git_storage, "git-auth-#{git_auth_key}")
      self.temporary_storage_path = temporary_storage_path

      # More details: https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage
      # Creates the `local_folder` directory if it does not exist
      FileUtils.mkdir_p(self.local_folder) unless File.directory?(self.local_folder)
      store_credentials_command = "git credential-store --file #{temporary_storage_path.shellescape} store"
      content = [
        "protocol=https",
        "host=#{repo_auth.remote_host}",
        "username=#{repo_auth.username}",
        "password=#{repo_auth.auth_token}",
        ""
      ].join("\n")

      scope = "local"

      unless File.directory?(File.join(self.local_folder, ".git"))
        # we don't have a git repo yet, we have no choice
        # TODO: check if we find a better way for the initial clone to work without setting system global state
        scope = "global"
      end
      use_credentials_command = "git config --#{scope} credential.helper 'store --file #{temporary_storage_path.shellescape}' #{self.local_folder}"

      # Uncomment if you want to debug git credential stuff, keeping it commented out because it's very noisey
      # logger.debug("Setting credentials for #{self.git_config.git_url} with command: #{use_credentials_command}")
      cmd = TTY::Command.new(printer: :quiet)
      cmd.run(store_credentials_command, input: content)
      cmd.run(use_credentials_command)
      return temporary_storage_path
    end

    def unset_auth
      return unless self.temporary_storage_path.kind_of?(String)
      # TODO: Also auto-clean those files from time to time, on server re-launch maybe, or background worker
      FileUtils.rm(self.temporary_storage_path) if File.exist?(self.temporary_storage_path)
    end

    def perform_block(use_global_git_mutex: true, &block)
      if use_global_git_mutex
        git_action_with_queue(ensure_block: proc { unset_auth }) { block.call }
      else
        block.call # Assuming all things in the block are synchronous
        self.unset_auth
      end
    end

    def pull(repo_auth: self.repo_auth, use_global_git_mutex: true)
      logger.debug("Enqueuing a pull on `master` (with mutex?: #{use_global_git_mutex}) for #{self.git_config.git_url}")
      self.perform_block(use_global_git_mutex: use_global_git_mutex) do
        logger.info("Starting pull #{self.git_config.git_url}")
        self.setup_auth(repo_auth: repo_auth)
        git.pull
        logger.debug("Done pulling #{self.git_config.git_url}")
      end
    end

    def checkout_branch(branch: nil, repo_auth: self.repo_auth, use_global_git_mutex: true)
      self.perform_block(use_global_git_mutex: use_global_git_mutex) do
        logger.info("Checking out branch: #{branch} from #{self.git_config.git_url}")
        self.setup_auth(repo_auth: repo_auth)
        git.branch(branch).checkout
        logger.debug("Done checking out branch: #{branch} from #{self.git_config.git_url}")
      end
    end

    def checkout_commit(sha: nil, repo_auth: self.repo_auth, use_global_git_mutex: true)
      self.perform_block(use_global_git_mutex: use_global_git_mutex) do
        logger.info("Checking out sha: #{sha} from #{self.git_config.git_url}")
        self.setup_auth(repo_auth: repo_auth)
        git.reset_hard(git.gcommit(sha))
        logger.debug("Done checking out sha: #{sha} from #{self.git_config.git_url}")
      end
    end

    # Discard any changes
    def reset_hard!(use_global_git_mutex: true)
      self.perform_block(use_global_git_mutex: use_global_git_mutex) do
        logger.debug("Starting reset_hard! #{self.git.branch.name} in #{self.git_config.git_url}".freeze)
        self.git.reset_hard
        self.git.clean(force: true, d: true)
        logger.debug("Done reset_hard! #{self.git.branch.name} in #{self.git_config.git_url}".freeze)
      end
    end

    # This method commits and pushes all changes
    # if `file_to_commit` is `nil`, all files will be added
    # TODO: this method isn't actually tested yet
    def commit_changes!(commit_message: nil, file_to_commit: nil, repo_auth: self.repo_auth)
      git_action_with_queue do
        logger.debug("Starting commit_changes! #{self.git_config.git_url} for #{repo_auth.username}")
        raise "file_to_commit not yet implemented" if file_to_commit
        commit_message ||= "Automatic commit by fastlane.ci"

        self.setup_author(full_name: repo_auth.full_name, username: repo_auth.username)

        git.add(all: true) # TODO: for now we only add all files
        changed = git.status.changed
        added = git.status.added
        deleted = git.status.deleted

        if changed.count == 0 && added.count == 0 && deleted.count == 0
          logger.debug("No changes in repo #{self.git_config.full_name}, skipping commit #{commit_message}")
        else
          git.commit(commit_message)
          logger.debug("Done commit_changes! #{self.git_config.full_name} for #{repo_auth.username}")
        end
      end
    end

    def push(repo_auth: self.repo_auth)
      git_action_with_queue(ensure_block: proc { unset_auth }) do
        logger.debug("Pushing to #{self.git_config.git_url}")
        self.setup_author(full_name: repo_auth.full_name, username: repo_auth.username)
        self.temporary_storage_path = self.setup_auth(repo_auth: repo_auth)
        # TODO: how do we handle branches
        self.git.push
        logger.debug("Done pushing to #{self.git_config.git_url}")
      end
    end

    def status
      self.git.status
    end

    # `ensure_block`: block that you want executed after the `&block` finishes executed, even on error
    def git_action_with_queue(ensure_block: nil, &block)
      git_task = TaskQueue::Task.new(work_block: block, ensure_block: ensure_block)
      GitRepo.git_action_queue.add_task_async(task: git_task)
      return git_task
    end

    def fetch
      git_action_with_queue(ensure_block: proc { unset_auth }) do
        logger.debug("Starting fetch #{self.git_config.git_url}".freeze)
        self.temporary_storage_path = self.setup_auth(repo_auth: repo_auth)
        self.git.fetch
        logger.debug("Done fetching #{self.git_config.git_url}".freeze)
      end
    end

    def switch_to_fork(clone_url:, branch:, sha: nil, local_branch_name:, use_global_git_mutex: false)
      self.perform_block(use_global_git_mutex: use_global_git_mutex) do
        logger.debug("Switching to branch #{branch} from forked repo: #{clone_url} (pulling into #{local_branch_name})")
        reset_hard!(use_global_git_mutex: false)
        # TODO: make sure it doesn't exist yet
        git.branch(local_branch_name)
        reset_hard!(use_global_git_mutex: false)
        git.pull(clone_url, branch)
      end
    end

    def clone(repo_auth: self.repo_auth, async: false)
      if async
        logger.debug("Asynchronously cloning #{self.git_config.git_url}".freeze)
        # If we're async, just push it on the queue
        git_action_with_queue(ensure_block: proc { unset_auth }) do
          clone_synchronously(repo_auth: repo_auth)
          logger.debug("Done asynchronously cloning of #{self.git_config.git_url}".freeze)
        end
      else
        logger.debug("Synchronously cloning #{self.git_config.git_url}".freeze)
        clone_synchronously(repo_auth: repo_auth)
        logger.debug("Done synchronously cloning of #{self.git_config.git_url}".freeze)
        unset_auth
      end
    end

    def callback_block(async_start)
      # How do we know that the task was successfully finished?
      return if self.callback.nil?
      return unless async_start

      self.callback.call(self)
    end

    private

    def clone_synchronously(repo_auth: self.repo_auth)
      # `@local_folder` is where we store the local git repo
      # fastlane.ci will also delete this directory if it breaks
      # and just re-clones. So make sure it's fine if it gets deleted
      raise "No local folder path available" unless self.local_folder
      logger.debug("Cloning git repo #{self.git_config.git_url}....")

      existing_repo_for_project = File.join(self.local_folder, self.git_config.id)
      # self.git_config.id.length > 1 to ensure we're not empty or a space
      if self.git_config.id.length > 1 && Dir.exist?(existing_repo_for_project)
        logger.debug("Removing existing repo at: #{existing_repo_for_project}")
        require "fileutils"
        # Danger zone
        FileUtils.rm_r(existing_repo_for_project)
      end

      self.temporary_storage_path = self.setup_auth(repo_auth: repo_auth)
      logger.debug("[#{self.git_config.id}]: Cloning git repo #{self.git_config.git_url} to #{@local_folder}")
      Git.clone(self.git_config.git_url,
                "", # checkout into the self.local_folder
                path: self.local_folder,
                recursive: true)
    end
  end
end
