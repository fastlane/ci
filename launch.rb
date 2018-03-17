require "set"
require_relative "./shared/logging_module"
require_relative "./shared/models/job_trigger"
require_relative "./shared/models/git_repo" # for GitRepo.git_action_queue
require_relative "./taskqueue/task_queue"

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
      require_fastlane_ci
      verify_dependencies
      verify_system_requirements
      Services.environment_variable_service.reload_dot_env!
      clone_repo_if_no_local_repo_and_remote_repo_exists

      # done making sure our env is sane, let's move on to the next step
      write_configuration_directories
      configure_thread_abort
      Services.reset_services!
      register_available_controllers
      Services.worker_service.start_github_workers
      Services.config_service.restart_any_pending_work
    end

    def self.require_fastlane_ci
      # before running, call `bundle install --path vendor/bundle`
      # this isolates the gems for bundler
      require "./fastlane_app"

      # allow use of `require` for all things under `shared`, helps with some cycle issues
      $LOAD_PATH << "shared"
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
    # not found, but the user has a `FastlaneCI.env.repo_url` which corresponds
    # to a valid remote configuration repository
    def self.clone_repo_if_no_local_repo_and_remote_repo_exists
      if !Services.onboarding_service.local_configuration_repo_exists? &&
         Services.onboarding_service.remote_configuration_repository_valid?
        Services.onboarding_service.trigger_initial_ci_setup
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
      require_relative "features/configuration/configuration_controller"
      require_relative "features/dashboard/dashboard_controller"
      require_relative "features/login/login_controller"
      require_relative "features/notifications/notifications_controller"
      require_relative "features/onboarding/onboarding_controller"
      require_relative "features/project/project_controller"
      require_relative "features/credentials/provider_credentials_controller"
      require_relative "features/users/users_controller"
      require_relative "features/build/build_controller"

      # Load up all the available controllers
      FastlaneCI::FastlaneApp.use(FastlaneCI::ConfigurationController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::DashboardController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::LoginController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::NotificationsController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::OnboardingController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::ProjectController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::ProviderCredentialsController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::UsersController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::BuildController)
    end
  end
end
