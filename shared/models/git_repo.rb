# We're using https://github.com/ruby-git/ruby-git
# for all git interactions
require "git"
require "tty-command"
require "securerandom"
require_relative "../logging_module"
require_relative "../../taskqueue/task_queue"

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

    class << self
      attr_accessor :git_action_queue
    end

    GitRepo.git_action_queue = TaskQueue::TaskQueue.new(name: "GitRepo task queue")

    def initialize(git_config: nil, provider_credential: nil, async_start: false, sync_setup_timeout_seconds: 120)
      self.validate_initialization_params!(git_config: git_config, provider_credential: provider_credential)
      @git_config = git_config

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

      logger.debug("Adding task to setup repo #{self.git_config.git_url} at: #{self.git_config.local_repo_path}")

      setup_task = git_action_with_queue do
        logger.debug("starting setup_repo #{self.git_config.git_url}".freeze)
        self.setup_repo
        logger.debug("done setup_repo #{self.git_config.git_url}".freeze)
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
        sleep(1)
        now = Time.now.utc
      end

      raise "Unable to start git repo #{git_config.git_url} in #{sync_setup_timeout_seconds} seconds" if now > sleep_timeout
      logger.debug("Done starting up repo: #{self.git_config.git_url}")
    end

    def setup_repo
      if File.directory?(self.git_config.local_repo_path)
        # TODO: test if this crashes if it's not a git directory
        @_git = Git.open(self.git_config.local_repo_path)
        repo = self.git
        if repo.index.writable?
          # Things are looking legit so far
          # Now we have to check if the repo is actually from the
          # same repo URL
          if repo.remote("origin").url.casecmp(self.git_config.git_url.downcase).zero?
            logger.debug("Resetting #{self.git_config.git_url}")
            self.git.reset_hard

            logger.debug("Pulling #{self.git_config.git_url}")
            self.pull
          else
            logger.debug("[#{self.git_config.id}] Repo URL seems to have changed... deleting the old directory and cloning again")
            self.clear_directory
            self.clone
          end
        else
          self.clear_directory
          logger.debug("Cloning #{self.git_config.git_url} into #{self.git_config.local_repo_path} after clearing directory")
          self.clone
        end
      else
        logger.debug("Cloning #{self.git_config.git_url} into #{self.git_config.local_repo_path}")
        self.clone

        # now that we've cloned, we can setup the @_git variable
        @_git = Git.open(self.git_config.local_repo_path)
      end
      logger.debug("Done, now using #{self.git_config.local_repo_path} for config repo")
    end

    def validate_initialization_params!(git_config: nil, provider_credential: nil)
      raise "No git config provided" if git_config.nil?
      raise "No provider_credential provided" if provider_credential.nil?

      credential_type = provider_credential.type
      git_config_credential_type = git_config.provider_credential_type_needed

      credential_mismatch = credential_type != git_config_credential_type
      raise "provider_credential.type and git_config.provider_credential_type_needed mismatch: #{credential_type} vs #{git_config_credential_type}" if credential_mismatch
    end

    def clear_directory
      logger.debug("Deleting #{self.git_config.local_repo_path}")
      FileUtils.rm_rf(self.git_config.local_repo_path)
    end

    # Returns the absolute path to a file from inside the git repo
    def file_path(file_path)
      File.join(self.git_config.local_repo_path, file_path)
    end

    def git
      return @_git
    end

    # call like you would self.git.branches.remote.each { |branch| branch.yolo }
    # call like you would, but you also get the git repo involved, so it's  .each { |git, branch| branch.yolo; git.yolo }
    def git_and_remote_branches_each(&each_block)
      git_action_with_queue do
        logger.debug("iterating through all remote branches of #{self.git_config.git_url}")
        branch_count = 0
        self.git.branches.remote.each do |branch|
          each_block.call(self.git, branch)
          branch_count = branch_count + 1
        end
        logger.debug("done iterating through all #{branch_count} remote branches of #{self.git_config.git_url}")
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
      logger.debug("Using #{full_name} with #{username} as author information on #{self.git_config.git_url}")
      git.config("user.name", full_name)
      git.config("user.email", username)
      logger.debug("done setup_author")
    end

    def temporary_git_storage
      @temporary_git_storage ||= File.expand_path("~/.fastlane/.tmp")
      FileUtils.mkdir_p(@temporary_git_storage)
      return @temporary_git_storage
    end

    # Responsible for using the auth token to be able to push/pull changes
    # from git remote
    def setup_auth(repo_auth: self.repo_auth)
      self.temporary_storage_path = File.join(self.temporary_git_storage, "git-auth-#{SecureRandom.uuid}")
      # More details: https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage
      local_repo_path = self.git_config.local_repo_path
      FileUtils.mkdir_p(local_repo_path) unless File.directory?(local_repo_path)

      store_credentials_command = "git credential-store --file #{self.temporary_storage_path.shellescape} store"
      content = [
        "protocol=https",
        "host=#{repo_auth.remote_host}",
        "username=#{repo_auth.username}",
        "password=#{repo_auth.auth_token}",
        ""
      ].join("\n")

      scope = "local"

      unless File.directory?(File.join(local_repo_path, ".git"))
        # we don't have a git repo yet, we have no choice
        # TODO: check if we find a better way for the initial clone to work without setting system global state
        scope = "global"
      end
      use_credentials_command = "git config --#{scope} credential.helper 'store --file #{self.temporary_storage_path.shellescape}' #{local_repo_path}"

      logger.debug("Setting credentials with command: #{use_credentials_command}")
      cmd = TTY::Command.new(printer: :quiet)
      cmd.run(store_credentials_command, input: content)
      cmd.run(use_credentials_command)
    end

    def unset_auth
      return unless self.temporary_storage_path.kind_of?(String)
      # TODO: Also auto-clean those files from time to time, on server re-launch maybe, or background worker
      FileUtils.rm(self.temporary_storage_path) if File.exist?(self.temporary_storage_path)
    end

    def pull(repo_auth: self.repo_auth)
      git_action_with_queue(ensure_block: proc { unset_auth }) do
        logger.info("Starting pull #{self.git_config.git_url}")
        logger.debug("setting auth in pull #{self.git_config.git_url}")
        self.setup_auth(repo_auth: repo_auth)
        logger.debug("done setting auth in pull #{self.git_config.git_url}")
        logger.debug("pulling #{self.git_config.git_url}")
        git.pull
        logger.debug("done pulling #{self.git_config.git_url}")
      end
    end

    # This method commits and pushes all changes
    # if `file_to_commit` is `nil`, all files will be added
    # TODO: this method isn't actually tested yet
    def commit_changes!(commit_message: nil, file_to_commit: nil, repo_auth: self.repo_auth)
      git_action_with_queue do
        logger.debug("starting commit_changes! #{self.git_config.git_url}")
        raise "file_to_commit not yet implemented" if file_to_commit
        commit_message ||= "Automatic commit by fastlane.ci"

        self.setup_author(full_name: repo_auth.full_name, username: repo_auth.username)

        git.add(all: true) # TODO: for now we only add all files
        git.commit(commit_message)
        git.push
        logger.debug("done commit_changes! #{self.git_config.git_url}")
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

    # Discard any changes
    def reset_hard!
      git_action_with_queue do
        logger.debug("starting reset_hard! #{self.git_config.git_url}".freeze)
        self.git.reset_hard
        self.git.clean(force: true, d: true)
        logger.debug("done reset_hard! #{self.git_config.git_url}".freeze)
      end
    end

    def fetch
      git_action_with_queue(ensure_block: proc { unset_auth }) do
        logger.debug("starting fetch #{self.git_config.git_url}".freeze)
        self.temporary_storage_path = self.setup_auth(repo_auth: repo_auth)
        self.git.fetch
        logger.debug("done fetching #{self.git_config.git_url}".freeze)
      end
    end

    def clone(repo_auth: self.repo_auth, async: false)
      if async
        # If we're async, just push it on the queue
        git_action_with_queue(ensure_block: proc { unset_auth }) do
          logger.debug("starting clone_synchronously of #{self.git_config.git_url}".freeze)
          clone_synchronously(repo_auth: repo_auth)
          logger.debug("done clone_synchronously of #{self.git_config.git_url}".freeze)
        end
      else
        clone_synchronously(repo_auth: repo_auth)
      end
    end

    private

    def clone_synchronously(repo_auth: self.repo_auth)
      # `self.git_config.containing_path` is where we store the local git repo
      # fastlane.ci will also delete this directory if it breaks
      # and just re-clones. So make sure it's fine if it gets deleted
      raise "No containing path available" unless self.git_config.containing_path
      logger.debug("Cloning git repo #{self.git_config.git_url}....")

      self.temporary_storage_path = self.setup_auth(repo_auth: repo_auth)
      logger.debug("[#{self.git_config.id}]: Cloning git repo #{self.git_config.git_url}")
      Git.clone(self.git_config.git_url, self.git_config.id,
                path: self.git_config.containing_path,
                recursive: true)
    end
  end
end
