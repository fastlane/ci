# We're using https://github.com/ruby-git/ruby-git
# for all git interactions
require "git"
require "tty-command"
require "securerandom"
require "digest"
require "task_queue"
require "faraday"
require "faraday-http-cache"
require "fileutils"

require_relative "../logging_module"

require_relative "../git_monkey_patches"

module FastlaneCI
  # Encapsulates all the data that is needed by GitRepo
  # We can have various provider_credentials, but they all need to be turned into `GitRepoAuth`s
  # This is because different git providers can have different needs for data
  # What github needs is an `api_token`, but a local git repo might only need a `password`.
  # We'll call both of these "auth_tokens" here, this way we can use GitRepoAuth
  # as a way to unify those, and prevent overloading names at the data source.
  # Otherwise, in the JSON we'd see "password" but for some repos that might be an auth_token, or an api_token, or
  # password
  class GitRepoAuth
    attr_reader :remote_host # in the case of github, this is usually `github.com`
    attr_reader :username    # whatever the git repo needs for a username, usually just an email, usually CI
    attr_reader :full_name   # whatever the git repo needs for a username, usually just an email, usually fastlane.CI
    attr_reader :auth_token # usually an API key, but could be a password, usually fastlane.CI's auth_token
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
  # rubocop:disable Metrics/ClassLength
  class GitRepo
    # rubocop:enable Metrics/ClassLength
    include FastlaneCI::Logging

    DEFAULT_REMOTE = "origin"

    # @return [RepoConfig]
    attr_accessor :git_config
    # @return [GitRepoAuth]
    attr_accessor :repo_auth # whatever pieces of information that can change between git users

    attr_accessor :temporary_storage_path

    attr_reader :credential_scope

    attr_reader :local_folder # where we are keeping the local repo checkout

    attr_reader :notification_service # when we have issues, we need to push them somewhere

    # This callback is used when the instance is initialized in async mode, so you can define a proc
    # with the final GitRepo configured.
    #   @example
    #   GitRepo.new(..., async_start: true, callback: proc { |repo| puts "This is my final repo #{repo}"; })
    #
    # @return [proc(GitRepo)]
    attr_accessor :callback

    class << self
      def pushes_disabled?
        push_state = ENV["FASTLANE_CI_DISABLE_PUSHES"]
        return false if push_state.nil?

        push_state = push_state.to_s
        return false if push_state == "false" || push_state == "0"

        return true
      end

      attr_reader :git_action_queue

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

    @git_action_queue = TaskQueue::TaskQueue.new(name: "GitRepo task queue")

    # Initializer for GitRepo class
    # @param git_config [GitConfig]
    # @param provider_credential [ProviderCredential]
    # @param async_start [Bool] Whether the repo should be setup async or not. (Defaults to `true`)
    # @param sync_setup_timeout_seconds [Integer] When in sync setup mode, how many seconds to wait until raise an
    #        exception. (Defaults to 300)
    # @param callback [proc(GitRepo)] When in async setup mode, the proc to be called with the final GitRepo setup.
    def initialize(
      git_config: nil,
      local_folder: nil,
      provider_credential: nil,
      async_start: false,
      sync_setup_timeout_seconds: 300,
      callback: nil,
      notification_service:
    )
      GitRepo.load_octokit_cache_stack
      logger.debug("Creating repo in #{local_folder} for a copy of #{git_config.git_url}")

      validate_initialization_params!(
        git_config: git_config,
        local_folder: local_folder,
        provider_credential: provider_credential,
        async_start: async_start,
        callback: callback
      )

      @git_config = git_config
      @local_folder = local_folder
      @callback = callback
      @notification_service = notification_service

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

      logger.debug("Adding task to setup repo #{git_config.git_url} at: #{local_folder}")

      setup_task = git_action_with_queue(ensure_block: proc { callback_block(async_start) }) do
        logger.debug("Starting setup_repo #{git_config.git_url}".freeze)
        setup_repo
        logger.debug("Done setup_repo #{git_config.git_url}".freeze)
      end

      # if we're starting asynchronously, we can return now.
      if async_start
        logger.debug("Asynchronously starting up repo: #{git_config.git_url}")
        return
      end

      logger.debug("Synchronously starting up repo: #{git_config.git_url} at: #{local_folder}")
      now = Time.now.utc
      sleep_timeout = now + sync_setup_timeout_seconds # 10 second startup timeout

      while !setup_task.completed && now < sleep_timeout
        time_left = sleep_timeout - now
        logger.debug("Not setup yet, sleeping (time before timeout: #{time_left.round}) #{git_config.git_url}")
        sleep(2)
        now = Time.now.utc
      end

      repo_url = git_config.git_url
      raise "Unable to start git repo #{repo_url} in #{sync_setup_timeout_seconds} seconds" if now > sleep_timeout
      logger.debug("Done starting up repo: #{repo_url}")
    end

    # Message is used to display custom logging in the console.
    def handle_exception(ex, console_message: nil, exception_context: {})
      unless console_message.nil?
        logger.error(console_message)
      end
      logger.error(ex)

      # No way to notify nicely? Alright, let's die X-(
      raise ex unless notification_service

      user_unfriendly_message = ex.message.to_s

      # Permission error, or lost interwebs
      if user_unfriendly_message.include?("unable to access")
        priority = Notification::PRIORITIES[:urgent]
        notification_service.create_notification!(
          priority: priority,
          name: "Repo access error",
          message: "Unable to acccess #{git_config.git_url}",
          details: user_unfriendly_message
        )

      # Sometimes we try to commit something and it fails because there was nothing added to the change set.
      elsif user_unfriendly_message.include?("no changes added to commit")
        priority = Notification::PRIORITIES[:warn]
        notification_service.create_notification!(
          priority: priority,
          name: "Repo syncing warning: no changes in added to commit error",
          message: "Unable to perform sync, the there are no changes added to the commit for #{git_config.git_url}",
          details: user_unfriendly_message
        )

      # Sometimes a repo is told to do something like commit when nothing is added to the change set
      # It's weird, and indicative of a race condition somewhere, so let's log it and move on
      elsif user_unfriendly_message.include?("Your branch is up to date with")
        priority = Notification::PRIORITIES[:warn]
        notification_service.create_notification!(
          priority: priority,
          name: "Repo syncing warning: up to date repo error",
          message: "Unable to perform sync, the repo is already up to date #{git_config.git_url}",
          details: user_unfriendly_message
        )

      # Merge conflict, maybe somebody force-pushed something?
      elsif user_unfriendly_message.include?("Merge conflict")
        priority = Notification::PRIORITIES[:urgent]
        notification_service.create_notification!(
          priority: priority,
          name: "Repo syncing error: merge conflict",
          message: "Unable to build #{git_config.git_url}",
          details: "#{user_unfriendly_message}, context: #{exception_context}"
        )

      # Object disappeared in current git tree, could have been a force push that now causes SHA  to be missing
      elsif user_unfriendly_message.include?("Could not parse object")
        # This happens when there is a force push somewhere and now a previous commit is missing
        # or a repo is just not up-to-date
        priority = Notification::PRIORITIES[:urgent]
        notification_service.create_notification!(
          priority: priority,
          name: "Unable to check out sha",
          message: "Unable to checkout an object from #{git_config.git_url}",
          details: "#{user_unfriendly_message}, context: #{exception_context}"
        )
      elsif user_unfriendly_message.include?("Couldn't find remote ref")
        # This happens when a branch is deleted but we try to pull it anyway
        priority = Notification::PRIORITIES[:urgent]
        notification_service.create_notification!(
          priority: priority,
          name: "Unable to checkout object",
          message: "Unable to checkout an object (probably a branch) from #{git_config.git_url}",
          details: "#{user_unfriendly_message}, context: #{exception_context}"
        )
      else
        raise ex
      end
    end

    def setup_repo
      retry_count ||= 0
      if File.directory?(local_folder)
        # TODO: test if this crashes if it's not a git directory
        begin
          @_git = Git.open(local_folder)
        rescue ArgumentError => aex
          logger.debug("Path #{local_folder} is not a git directory, deleting and trying again")
          clear_directory
          clone
          retry if (retry_count += 1) < 5
          raise "Exceeded retry count for #{__method__}. Exception: #{aex}"
        end
        # Git will not allow to commit with an empty name or empty email
        # (e.g. on a shared box which has no global git config)
        setup_author(full_name: repo_auth.full_name, username: repo_auth.username)
        repo = git
        if repo.index.writable?
          # Things are looking legit so far
          # Now we have to check if the repo is actually from the
          # same repo URL
          if repo.remote(GitRepo::DEFAULT_REMOTE).url.casecmp(git_config.git_url.downcase).zero?
            # If our courrent repo is the ci-config repo and has changes on it, we should commit them before
            # other actions, to prevent local changes to be lost.
            # This is a common issue, ci_config repo gets recreated several times trough the
            # Services.configuration_git_repo and if some changes in the local repo (added projects, etc.) have been
            # added, they're destroyed.
            # rubocop:disable Metrics/BlockNesting
            if local_folder == File.expand_path("~/.fastlane/ci/fastlane-ci-config")
              # TODO: move this stuff out of here
              # TODO: In case there are conflicts with remote, we want to decide which way we take.
              # For now, we merge using the 'recursive' strategy.
              if repo.status.changed.count > 0 ||
                 repo.status.added.count > 0 ||
                 repo.status.deleted.count > 0 ||
                 repo.status.untracked.count > 0
                begin
                  repo.add(all: true)
                  repo.commit("Sync changes")
                  git.push(GitRepo::DEFAULT_REMOTE, "master", force: true) unless GitRepo.pushes_disabled?
                rescue StandardError => ex
                  handle_exception(ex, console_message: "Error commiting changes to ci-config repo")
                end
              end
            else
              logger.debug("Resetting #{git_config.git_url} in setup_repo")
              begin
                git.reset_hard
                logger.debug("Ensuring we're on `master` for #{git_config.git_url} in setup_repo")
                git.branch("master").checkout
                logger.debug("Resetting `master` #{git_config.git_url} in setup_repo")
                git.reset_hard

                logger.debug("Pulling `master` #{git_config.git_url} in setup_repo")
                pull
              rescue StandardError => ex
                handle_exception(ex, console_message: "Error commiting changes to ci-config repo")
              end
            end
          else
            logger.debug(
              "[#{git_config.id}] Repo URL seems to have changed... deleting the old directory and cloning again"
            )
            clear_directory
            clone
          end
        else
          clear_directory
          logger.debug("Cloning #{git_config.git_url} into #{local_folder} after clearing directory")
          clone
        end
      else
        logger.debug("Cloning #{git_config.git_url} into #{local_folder}")
        clone

        # now that we've cloned, we can setup the @_git variable
        @_git = Git.open(local_folder)
      end
      logger.debug("Done, now using #{local_folder} for #{git_config.git_url}")
      # rubocop:enable Metrics/BlockNesting
    end

    def validate_initialization_params!(
      git_config: nil,
      local_folder: nil,
      provider_credential: nil,
      async_start: nil,
      callback: nil
    )
      raise "No git config provided" if git_config.nil?
      raise "No local_folder provided" if local_folder.nil?
      raise "No provider_credential provided" if provider_credential.nil?
      raise "Callback provided but not initialized in async mode" if !callback.nil? && !async_start

      credential_type = provider_credential.type
      git_config_credential_type = git_config.provider_credential_type_needed

      credential_mismatch = credential_type != git_config_credential_type

      if credential_mismatch
        # rubocop:disable Metrics/LineLength
        raise "provider_credential.type and git_config.provider_credential_type_needed mismatch: #{credential_type} vs #{git_config_credential_type}"
        # rubocop:enable Metrics/LineLength
      end
    end

    def clear_directory
      logger.debug("Deleting #{local_folder}")
      FileUtils.rm_rf(local_folder)
    end

    # Returns the absolute path to a file from inside the git repo
    def file_path(file_path)
      File.join(local_folder, file_path)
    end

    def git
      return @_git
    end

    # call like you would git.branches.remote.each { |branch| branch.yolo }
    # call like you would, but you also get the git repo involved, so it's .each { |git, branch| branch.yolo; git.yolo }
    def git_and_remote_branches_each_async(&each_block)
      git_action_with_queue do
        branch_count = 0
        git.branches.remote.each do |branch|
          each_block.call(git, branch)
          branch_count += 1
        end
      end
    end

    # Return the last commit, that isn't a merge commit
    # Make sure to have checked out the right branch for which
    # you want to get the last commit of
    def most_recent_commit
      return git.log.first
    end

    # Responsible for setting the author information when committing a change
    # NOT PROTECTED BY QUEUE, ONLY CALL WHEN INSIDE A git_action_queue BLOCK
    def setup_author(full_name: repo_auth.full_name, username: repo_auth.username)
      # TODO: performance implications of settings this every time?
      # TODO: Set actual name + email here
      # TODO: see if we can set credentials here also
      if full_name.nil? || full_name.length == 0
        full_name = "Unknown user"
      end
      logger.debug("Using #{full_name} with #{username} as author information on #{git_config.git_url}")
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
      git_auth_key = Digest::SHA2.hexdigest(repo_auth.remote_host + repo_auth.username + git_config.git_url)
      self.temporary_storage_path = File.join(temporary_git_storage, "git-auth-#{git_auth_key}")

      # More details: https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage
      # Creates the `local_folder` directory if it does not exist
      FileUtils.mkdir_p(local_folder) unless File.directory?(local_folder)
      store_credentials_command = "git credential-store --file #{temporary_storage_path.shellescape} store"
      content = [
        "protocol=https",
        "host=#{repo_auth.remote_host}",
        "username=#{repo_auth.username}",
        "password=#{repo_auth.auth_token}",
        ""
      ].join("\n")

      # we don't have a git repo yet, we have no choice and must use global
      # TODO: check if we find a better way for the initial clone to work without setting system global state
      @credential_scope = File.directory?(File.join(local_folder, ".git")) ? "local" : "global"

      # rubocop:disable Metrics/LineLength
      use_credentials_command = "git config --#{credential_scope} credential.helper 'store --file #{temporary_storage_path.shellescape}' #{local_folder}"
      # rubocop:enable Metrics/LineLength

      # Uncomment next line if you want to debug git credential stuff, it's very noisey
      # logger.debug("Setting credentials for #{git_config.git_url} with command: #{use_credentials_command}")
      cmd = TTY::Command.new(printer: :quiet)
      cmd.run(store_credentials_command, input: content)
      cmd.run(use_credentials_command)
      return temporary_storage_path
    end

    # any calls to this should be balanced with any calls to set_auth
    def unset_auth
      return unless temporary_storage_path.kind_of?(String)
      # TODO: Also auto-clean those files from time to time, on server re-launch maybe, or background worker
      FileUtils.rm(temporary_storage_path) if File.exist?(temporary_storage_path)

      # Disable for now, need to refine it since we're causing issues
      # clear_credentials_command = "git config --#{credential_scope} --replace-all credential.helper \"\""

      ## Uncomment next line if you want to debug git credential stuff, it's very noisey
      ## logger.debug("Clearing credentials for #{git_config.git_url} with command: #{clear_credentials_command}")
      # cmd = TTY::Command.new(printer: :quiet)
      # cmd.run(clear_credentials_command)
    end

    def perform_block(use_global_git_mutex: true, &block)
      if use_global_git_mutex
        git_action_with_queue(ensure_block: proc { unset_auth }) { block.call }
      else
        block.call # Assuming all things in the block are synchronous
        unset_auth
      end
    end

    def pull(repo_auth: self.repo_auth, use_global_git_mutex: true)
      logger.debug("Enqueuing a pull (with mutex?: #{use_global_git_mutex}) for #{git_config.git_url}")
      perform_block(use_global_git_mutex: use_global_git_mutex) do
        logger.info("Starting pull #{git_config.git_url}")
        setup_auth(repo_auth: repo_auth)

        begin
          git.pull
        rescue StandardError => ex
          handle_exception(ex, console_message: "Error pulling #{git_config.git_url}")
        end

        logger.debug("Done pulling #{git_config.git_url}")
      end
    end

    def checkout_branch(branch: nil, repo_auth: self.repo_auth, use_global_git_mutex: true)
      perform_block(use_global_git_mutex: use_global_git_mutex) do
        logger.info("Checking out branch: #{branch} from #{git_config.git_url}")
        setup_auth(repo_auth: repo_auth)

        begin
          git.branch(branch).checkout
        rescue StandardError => ex
          handle_exception(ex, console_message: "Error checking out #{git_config.git_url}, branch: #{branch}")
        end

        logger.debug("Done checking out branch: #{branch} from #{git_config.git_url}")
      end
    end

    def checkout_commit(sha: nil, repo_auth: self.repo_auth, use_global_git_mutex: true, completion_block: nil)
      perform_block(use_global_git_mutex: use_global_git_mutex) do
        repo_url = git_config.git_url
        logger.info("Checking out sha: #{sha} from #{repo_url}")
        setup_auth(repo_auth: repo_auth)

        success = false
        begin
          git.gcommit(sha)

          success = true
        rescue StandardError => ex
          exception_context = { sha: sha }
          handle_exception(
            ex,
            console_message: "Error resetting and checking out sha: #{sha} from #{repo_url}",
            exception_context: exception_context
          )
        ensure
          if success
            logger.debug("Done resetting and checking out sha: #{sha} from #{repo_url}")
          end

          completion_block.call(success) unless completion_block.nil?
        end
      end
    end

    # Discard any changes
    def reset_hard!(use_global_git_mutex: true)
      perform_block(use_global_git_mutex: use_global_git_mutex) do
        repo_url = git_config.git_url
        logger.debug("Starting reset_hard! #{git.branch.name} in #{repo_url}".freeze)

        begin
          git.reset_hard
          git.clean(force: true, d: true)
        rescue StandardError => ex
          handle_exception(ex, console_message: "Error resetting and cleaning #{git.branch.name} in #{repo_url}")
        end

        logger.debug("Done reset_hard! #{git.branch.name} in #{repo_url}".freeze)
      end
    end

    # This method commits and pushes all changes
    # if `files_to_commit` is empty or nil, all files will be added
    # TODO: this method isn't actually tested yet
    def commit_changes!(commit_message: nil, push_after_commit: true, files_to_commit: [], repo_auth: self.repo_auth)
      git_action_with_queue do
        logger.debug("Starting commit_changes! #{git_config.git_url} for #{repo_auth.username}")
        commit_message ||= "Automatic commit by fastlane.ci"

        setup_author(full_name: repo_auth.full_name, username: repo_auth.username)

        if files_to_commit.nil? || files_to_commit.empty?
          git.add(all: true)
        else
          git.add(files_to_commit)
        end
        changed = git.status.changed
        added = git.status.added
        deleted = git.status.deleted

        if changed.count == 0 && added.count == 0 && deleted.count == 0
          logger.debug("No changes in repo #{git_config.full_name}, skipping commit #{commit_message}")
        else
          begin
            git.commit(commit_message)
          rescue StandardError => ex
            handle_exception(ex, console_message: "Error committing to #{git_config.git_url}")
          end

          unless GitRepo.pushes_disabled?
            push(use_global_git_mutex: false) if push_after_commit
          end

          logger.debug("Done commit_changes! #{git_config.full_name} for #{repo_auth.username}")
        end
      end
    end

    def push(use_global_git_mutex: true, repo_auth: self.repo_auth)
      if GitRepo.pushes_disabled?
        logger.debug("Skipping push to #{git_config.git_url}, pushes are disable")
        return
      end

      perform_block(use_global_git_mutex: use_global_git_mutex) do
        logger.debug("Pushing to #{git_config.git_url}")
        setup_author(full_name: repo_auth.full_name, username: repo_auth.username)
        self.temporary_storage_path = setup_auth(repo_auth: repo_auth)
        # TODO: how do we handle branches

        begin
          git.push
        rescue StandardError => ex
          handle_exception(ex, console_message: "Error pushing to #{git_config.git_url}")
        end

        logger.debug("Done pushing to #{git_config.git_url}")
      end
    end

    def status
      git.status
    end

    # `ensure_block`: block that you want executed after the `&block` finishes executed, even on error
    def git_action_with_queue(ensure_block: nil, &block)
      git_task = TaskQueue::Task.new(work_block: block, ensure_block: ensure_block)
      GitRepo.git_action_queue.add_task_async(task: git_task)
      return git_task
    end

    def fetch(use_global_git_mutex: true)
      logger.debug("Enqueuing a fetch on (with mutex?: #{use_global_git_mutex}) for #{git_config.git_url}")
      perform_block(use_global_git_mutex: use_global_git_mutex) do
        logger.debug("Starting fetch #{git_config.git_url}".freeze)
        self.temporary_storage_path = setup_auth(repo_auth: repo_auth)

        begin
          git.remotes.each { |remote| git.fetch(remote) }
        rescue StandardError => ex
          handle_exception(ex, console_message: "Error fetching each remote from #{git_config.git_url}")
        end

        logger.debug("Done fetching #{git_config.git_url}".freeze)
      end
    end

    # If we only have a git repo, and it isn't specifically from GitHub, we need to use this to switch to a fork
    # May cause merge conflicts, so don't use it unless we must.
    def switch_to_git_fork(clone_url:, branch:, sha: nil, local_branch_name:, use_global_git_mutex: false)
      perform_block(use_global_git_mutex: use_global_git_mutex) do
        logger.debug("Switching to branch #{branch} from forked repo: #{clone_url} (pulling into #{local_branch_name})")

        begin
          git.branch(local_branch_name).checkout
          git.pull(clone_url, branch)
          return true
        rescue StandardError => ex
          exception_context = {
            clone_url: clone_url,
            branch: branch,
            sha: sha,
            local_branch_name: local_branch_name
          }
          handle_exception(
            ex,
            console_message: "Error switching to a fork: #{clone_url}, branch: #{branch}",
            exception_context: exception_context
          )
          return false
        end
      end
    end

    def switch_to_ref(git_fork_config:, local_branch_name:, use_global_git_mutex: false)
      perform_block(use_global_git_mutex: use_global_git_mutex) do
        begin
          ref = "#{git_fork_config.ref}:#{local_branch_name}"
          logger.debug("Switching to new branch from ref #{ref} (pulling into #{local_branch_name})")
          git.fetch(GitRepo::DEFAULT_REMOTE, { ref: ref })
          git.branch(local_branch_name)
          git.checkout(local_branch_name)
          return true
        rescue StandardError => ex
          exception_context = {
            clone_url: git_fork_config.clone_url,
            branch: git_fork_config.branch,
            sha: git_fork_config.sha,
            local_branch_name: local_branch_name
          }
          handle_exception(
            ex,
            console_message: "Error switching to ref: #{ref}",
            exception_context: exception_context
          )
          return false
        end
      end
    end

    # Useful when you don't have a PR, if you have access to a PR, use :switch_to_github_pr
    def switch_to_fork(git_fork_config:, local_branch_prefex:, use_global_git_mutex: false)
      local_branch_name = local_branch_prefex + git_fork_config.sha[0..7]

      # if we have a git ref to work with, use that instead of the fork
      if git_fork_config.ref
        switch_to_ref(
          git_fork_config: git_fork_config,
          local_branch_name: local_branch_name,
          use_global_git_mutex: use_global_git_mutex
        )
      else
        switch_to_git_fork(
          clone_url: git_fork_config.clone_url,
          branch: git_fork_config.branch,
          sha: git_fork_config.sha,
          local_branch_name: local_branch_name,
          use_global_git_mutex: use_global_git_mutex
        )
      end
    end

    def clone(repo_auth: self.repo_auth, async: false)
      if async
        logger.debug("Asynchronously cloning #{git_config.git_url}".freeze)
        # If we're async, just push it on the queue
        git_action_with_queue(ensure_block: proc { unset_auth }) do
          clone_synchronously(repo_auth: repo_auth)
          logger.debug("Done asynchronously cloning of #{git_config.git_url}".freeze)
        end
      else
        logger.debug("Synchronously cloning #{git_config.git_url}".freeze)
        clone_synchronously(repo_auth: repo_auth)
        logger.debug("Done synchronously cloning of #{git_config.git_url}".freeze)
        unset_auth
      end
    end

    def callback_block(async_start)
      # How do we know that the task was successfully finished?
      return if callback.nil?
      return unless async_start

      callback.call(self)
    end

    private

    def clone_synchronously(repo_auth: self.repo_auth)
      # `@local_folder` is where we store the local git repo
      # fastlane.ci will also delete this directory if it breaks
      # and just re-clones. So make sure it's fine if it gets deleted
      raise "No local folder path available" unless local_folder
      logger.debug("Cloning git repo #{git_config.git_url}....")

      existing_repo_for_project = File.join(local_folder, git_config.id)
      # git_config.id.length > 1 to ensure we're not empty or a space
      if git_config.id.length > 1 && Dir.exist?(existing_repo_for_project)
        logger.debug("Removing existing repo at: #{existing_repo_for_project}")

        # Danger zone
        FileUtils.rm_r(existing_repo_for_project)
      end

      self.temporary_storage_path = setup_auth(repo_auth: repo_auth)
      logger.debug("[#{git_config.id}]: Cloning git repo #{git_config.git_url} to #{@local_folder}")

      begin
        Git.clone(
          git_config.git_url,
          "", # checkout into the local_folder
          path: local_folder,
          recursive: true
        )
      rescue StandardError => ex
        handle_exception(ex, console_message: "Error cloning #{git_config.git_url} to #{@local_folder}")
      end
    end
  end
end
