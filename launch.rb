require "set"
require "task_queue"
require_relative "app/shared/logging_module"
require_relative "app/shared/models/job_trigger"
require_relative "app/shared/models/git_fork_config"
require_relative "app/shared/models/git_repo" # for GitRepo.git_action_queue

module FastlaneCI
  # Launch is responsible for spawning up the whole
  # fastlane.ci server, this includes all needed classes
  # workers, check for .env, env variables and dependencies
  # This is being called from `config.ru`
  class Launch
    class << self
      include FastlaneCI::Logging
    end

    def self.take_off
      @launch_queue = TaskQueue::TaskQueue.new(name: "fastlane.ci launch queue")

      require_fastlane_ci
      verify_app_built
      verify_dependencies
      verify_system_requirements
      Services.dot_keys_variable_service.reload_dot_env!
      clone_repo_if_no_local_repo_and_remote_repo_exists

      # done making sure our env is sane, let's move on to the next step
      write_configuration_directories
      configure_thread_abort
      Services.reset_services!

      # order matters here
      cleanup_old_checkouts

      register_available_controllers
      start_github_workers
      restart_any_pending_work
    end

    def self.require_fastlane_ci
      # before running, call `bundle install --path vendor/bundle`
      # this isolates the gems for bundler
      require "./fastlane_app"

      # allow use of `require` for all things under `shared`, helps with some cycle issues
      $LOAD_PATH << "app/shared"
    end

    def self.verify_app_built
      unless ENV["FASTLANE_CI_ERB_CLIENT"]
        app_exists = File.file?(File.join("public", ".dist", "index.html"))

        unless app_exists
          raise "The web app not built. Build with the Angular CLI and Try Again, e.g. ng build --deploy-url=\"/.dist\""
        end
      end
    end

    def self.cleanup_old_checkouts
      return unless ENV["FASTLANE_CI_CLEANUP_OLD_CHECKOUTS"]

      all_projects = Services.config_service.projects(provider_credential: Services.provider_credential)

      # find all projects that are not the fastlane-ci-config
      non_config_projects = all_projects.select do |project|
        # don't include fastlane-ci-config
        # add some protection for accidental directory deletion, if the directory is `.` or `` we'll kills stuff on
        # accident. so just say if it's > 5 chars long, it's probably an actual ID and not a bug
        project.id != "fastlane-ci-config" && project.id.to_s.length > 5
      end

      non_config_projects.each do |project|
        FileUtils.rm_rf(File.join(File.expand_path("~/.fastlane/ci/"), project.id))
      end
    end

    def self.verify_dependencies
      require "openssl"
    rescue LoadError
      warn("Error: no such file to load -- openssl. Make sure you have openssl installed")
      exit(1)
    end

    def self.write_configuration_directories
      containing_path = File.expand_path("~/.fastlane/ci/")
      notifications_path = File.join(containing_path, "notifications")
      FileUtils.mkdir_p(notifications_path)
    end

    def self.verify_system_requirements
      # Check the current ruby version
      required_version = Gem::Version.new("2.3.0")
      if Gem::Version.new(RUBY_VERSION) < required_version
        warn("Error: ensure you have at least Ruby #{required_version}")
        exit(1)
      end
    end

    # Will clone the remote configuration repository if the local repository is
    # not found, but the user has a `FastlaneCI.dot_keys.repo_url` which corresponds
    # to a valid remote configuration repository
    def self.clone_repo_if_no_local_repo_and_remote_repo_exists
      if !Services.onboarding_service.local_configuration_repo_exists? &&
         Services.onboarding_service.required_keys_and_proper_remote_configuration_repo?
        Services.onboarding_service.clone_remote_repository_locally
      end
    end

    def self.configure_thread_abort
      if ENV["RACK_ENV"] == "development"
        logger.info("development mode, aborting on any thread exceptions")
        Thread.abort_on_exception = true
      end
    end

    # We can't actually launch the server here
    # as it seems like it has to happen in `config.ru`
    def self.register_available_controllers
      # require all controllers
      require_relative "app/features/all"
      # Load up all the available controllers

      if ENV["FASTLANE_CI_ERB_CLIENT"]
        # NOTE: ORDER MATTERS HERE
        # If using REST-style endpoints, you must list the controllers from
        # the outter most first.
        # Example:
        # BuildController is `project/build/*`
        # ProjectControoler is `project/*`
        # BuildController build be `used` first, so it is defined here first
        FastlaneCI::FastlaneApp.use(FastlaneCI::BuildController)
        FastlaneCI::FastlaneApp.use(FastlaneCI::ProjectController)
        FastlaneCI::FastlaneApp.use(FastlaneCI::ConfigurationController)
        FastlaneCI::FastlaneApp.use(FastlaneCI::DashboardController)
        FastlaneCI::FastlaneApp.use(FastlaneCI::NotificationsController)
        FastlaneCI::FastlaneApp.use(FastlaneCI::ProviderCredentialsController)
        FastlaneCI::FastlaneApp.use(FastlaneCI::UsersController)
        FastlaneCI::FastlaneApp.use(FastlaneCI::EnvironmentVariablesController)
        FastlaneCI::FastlaneApp.use(FastlaneCI::XcodeManagerController)
        FastlaneCI::FastlaneApp.use(FastlaneCI::AppleIDController)
      end

      # TODO: Only load this with ERB_CLIENT env once Web app has login/onboarding support
      FastlaneCI::FastlaneApp.use(FastlaneCI::LoginController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::OnboardingController)

      # Load JSON controllers
      require_relative "app/features-json/project_json_controller"
      require_relative "app/features-json/repos_json_controller"
      require_relative "app/features-json/login_json_controller"
      require_relative "app/features-json/user_json_controller"
      require_relative "app/features-json/build_json_controller"
      require_relative "app/features-json/artifact_json_controller"
      require_relative "app/features-json/setup_json_controller"
      require_relative "app/features-json/setting_json_controller"

      FastlaneCI::FastlaneApp.use(FastlaneCI::LoginJSONController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::ProjectJSONController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::RepositoryJSONController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::BuildJSONController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::ArtifactJSONController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::SetupJSONController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::SettingJSONController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::UserJSONController)
    end

    def self.start_github_workers
      return unless Services.onboarding_service.correct_setup?

      launch_workers unless ENV["FASTLANE_CI_SKIP_WORKER_LAUNCH"]
    end

    def self.restart_any_pending_work
      return unless Services.onboarding_service.correct_setup?

      # this helps during debugging
      # in the future we should allow this to be configurable behavior
      return if ENV["FASTLANE_CI_SKIP_RESTARTING_PENDING_WORK"]

      github_projects = Services.config_service.projects(provider_credential: Services.provider_credential)
      github_service = FastlaneCI::GitHubService.new(provider_credential: Services.provider_credential)

      restart_pending_builds_task = TaskQueue::Task.new(work_block: proc {
        run_pending_github_builds(projects: github_projects, github_service: github_service)
      })
      @launch_queue.add_task_async(task: restart_pending_builds_task)

      start_builds_for_prs_with_no_status_builds_task = TaskQueue::Task.new(work_block: proc {
        enqueue_builds_for_open_github_prs_with_no_status(projects: github_projects, github_service: github_service)
      })
      @launch_queue.add_task_async(task: start_builds_for_prs_with_no_status_builds_task)
    end

    def self.launch_workers
      logger.debug("Starting workers to monitor projects")
      # Iterate through all provider credentials and their projects and start a worker for each project
      Services.ci_user.provider_credentials.each do |provider_credential|
        projects = Services.config_service.projects(provider_credential: provider_credential)
        projects.each do |project|
          Services.worker_service.start_workers_for_project_and_credential(
            project: project,
            provider_credential: provider_credential,
            notification_service: Services.notification_service
          )
        end
      end

      if Services.worker_service.num_workers.zero?
        logger.info("Seems like no workers were started to monitor your projects")
      end

      # Initialize the workers
      # For now, we're not using a fancy framework that adds multiple heavy dependencies
      # including a database, etc.
      FastlaneCI::RefreshConfigDataSourcesWorker.new
      FastlaneCI::CheckForFastlaneCIUpdateWorker.new
    end

    # In the event of a server crash, we want to run pending builds on server
    # initialization for all projects for the provider credentials
    #
    # @return [nil]
    def self.run_pending_github_builds(projects: nil, github_service: nil)
      logger.debug("Searching all projects for commits with pending status that need a new build")
      # For each project, rerun all builds with the status of "pending"
      projects.each do |project|
        # Don't enqueue builds for the open pull requests if we don't have a pull request trigger defined for it
        next if project.find_triggers_of_type(trigger_type: :pull_request).first.nil?

        pending_build_shas_needing_rebuilds = Services.build_service.pending_build_shas_needing_rebuilds(
          project: project
        )

        if pending_build_shas_needing_rebuilds.count.zero?
          logger.debug("No pending work to reschedule for #{project.project_name}")
        end

        repo_full_name = project.repo_config.full_name
        # We have a list of shas that need rebuilding, but we need to know which repo_full_name they belong to
        # because they could be forks of the main repo, so let's grab all that info
        open_pull_requests = github_service.open_pull_requests(repo_full_name: repo_full_name)

        # Enqueue each pending build rerun in an asynchronous task queue
        pending_build_shas_needing_rebuilds.each do |sha|
          logger.debug("Found sha #{sha} that needs a rebuild for #{project.project_name}")
          next unless Services.build_runner_service.find_build_runner(project_id: project.id, sha: sha).nil?

          # Did we match a commit sha with an open pull request?
          matching_open_pr = open_pull_requests.detect { |open_pr| open_pr.current_sha == sha }

          if matching_open_pr.nil?
            logger.debug(
              "We have sha: #{sha} needing rebuild, but it doesn't belong to an open pr, so we're gonna skip it."
            )
            next
          end

          git_fork_config = GitForkConfig.new(
            sha: sha,
            branch: matching_open_pr.branch,
            clone_url: matching_open_pr.clone_url,
            ref: matching_open_pr.git_ref
          )

          build_runner = RemoteRunner.new(
            project: project,
            github_service: github_service,
            git_fork_config: git_fork_config,
            trigger: project.find_triggers_of_type(trigger_type: :pull_request).first
          )
          Services.build_runner_service.add_build_runner(build_runner: build_runner)
        end
      end
    end

    # We might be in a situation where we have an open pr, but no status yet
    # if that's the case, we should enqueue a build for it
    def self.enqueue_builds_for_open_github_prs_with_no_status(projects: nil, github_service: nil)
      logger.debug("Searching for open PRs with no status and starting a build for them")
      projects.each do |project|
        # Don't enqueue builds for the open pull requests if we don't have a pull request trigger defined for it
        next if project.find_triggers_of_type(trigger_type: :pull_request).first.nil?

        # TODO: generalize this sort of thing
        credential_type = project.repo_config.provider_credential_type_needed

        # we don't support anything other than GitHub right now
        next unless credential_type == FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]

        repo_full_name = project.repo_config.full_name
        # let's get all commit shas that need a build (no status yet)
        open_prs = github_service.open_pull_requests(repo_full_name: repo_full_name)

        # no commit shas need to be switched to `pending` state
        next unless open_prs.count > 0

        open_prs.each do |open_pr|
          logger.debug("Checking #{open_pr.repo_full_name} sha: #{open_pr.current_sha} for missing status")
          statuses = github_service.statuses_for_commit_sha(
            repo_full_name: open_pr.repo_full_name,
            sha: open_pr.current_sha
          )

          # if we have a status, skip it!
          next if statuses.count > 0

          logger.debug("Found sha: #{open_pr.current_sha} in #{open_pr.repo_full_name} missing status, adding build.")

          git_fork_config = GitForkConfig.new(
            sha: open_pr.current_sha,
            branch: open_pr.branch,
            clone_url: open_pr.clone_url,
            ref: open_pr.git_ref
          )

          build_runner = RemoteRunner.new(
            project: project,
            github_service: github_service,
            git_fork_config: git_fork_config,
            trigger: project.find_triggers_of_type(trigger_type: :pull_request).first
          )

          Services.build_runner_service.add_build_runner(build_runner: build_runner)
        end
      end
    end
  end
end
