require_relative "./shared/logging_module"

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
      verify_dependencies
      verify_system_requirements
      load_dot_env
      verify_env_variables
      setup_threads
      require_fastlane_ci
      check_for_existing_setup
      prepare_server
      launch_workers
    end

    def self.require_fastlane_ci
      # before running, call `bundle install --path vendor/bundle`
      # this isolates the gems for bundler
      require "./fastlane_app"

      # allow use of `require` for all things under `shared`, helps with some cycle issues
      $LOAD_PATH << "shared"
    end

    def self.load_dot_env
      return unless File.exist?(".keys")

      require "dotenv"
      Dotenv.load(".keys")
    end

    def self.verify_dependencies
      require "openssl"
    rescue LoadError
      warn("Error: no such file to load -- openssl. Make sure you have openssl installed")
      exit(1)
    end

    def self.verify_system_requirements
      # Check the current ruby version
      required_version = Gem::Version.new("2.3.0")
      if Gem::Version.new(RUBY_VERSION) < required_version
        warn("Error: ensure you have at least Ruby #{required_version}")
        exit(1)
      end
    end

    def self.verify_env_variables
      # Don't even try to run without having those
      if ENV["FASTLANE_CI_ENCRYPTION_KEY"].nil?
        warn("Error: unable to decrypt sensitive data without environment variable `FASTLANE_CI_ENCRYPTION_KEY` set")
        exit(1)
      end

      if ENV["FASTLANE_CI_USER"].nil? || ENV["FASTLANE_CI_PASSWORD"].nil?
        warn("Error: ensure you have your `FASTLANE_CI_USER` and `FASTLANE_CI_PASSWORD`environment variables set")
        exit(1)
      end

      if ENV["FASTLANE_CI_REPO_URL"].nil?
        warn("Error: ensure you have your `FASTLANE_CI_REPO_URL` environment variable set")
        exit(1)
      end
    end

    def self.setup_threads
      if ENV["RACK_ENV"] == "development"
        logger.info("development mode, aborting on any thread exceptions")
        Thread.abort_on_exception = true
      end
    end

    # Check if fastlane.ci already ran on this machine
    # and with that, have the initial `users.json`, etc.
    # If not, this is where we do the initial clone
    def self.check_for_existing_setup
      # TODO: should we also trigger a blocking `git pull` here?
      unless self.ci_config_repo.exists?
        self.trigger_initial_ci_setup
      end

      Services.ci_config_repo = self.ci_config_repo
    end

    def self.ci_config_repo
      # Setup the fastlane.ci GitRepoConfig
      @_ci_config_repo ||= GitRepoConfig.new(
        id: "fastlane-ci-config",
        git_url: ENV["FASTLANE_CI_REPO_URL"],
        description: "Contains the fastlane.ci configuration",
        name: "fastlane ci",
        hidden: true
      )
    end

    # We can't actually launch the server here
    # as it seems like it has to happen in `config.ru`
    def self.prepare_server
      # require all controllers
      require_relative "features/dashboard/dashboard_controller"
      require_relative "features/login/login_controller"
      require_relative "features/project/project_controller"

      # Load up all the available controllers
      FastlaneCI::FastlaneApp.use(FastlaneCI::DashboardController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::LoginController)
      FastlaneCI::FastlaneApp.use(FastlaneCI::ProjectController)
    end

    def self.launch_workers
      # Iterate through all provider credentials and their projects and start a worker for each project
      number_of_workers_started = 0
      Services.ci_user.provider_credentials.each do |provider_credential|
        projects = Services.config_service.projects(provider_credential: provider_credential)
        projects.each do |project|
          Services.worker_service.start_worker_for_provider_credential_and_config(
            project: project,
            provider_credential: provider_credential
          )
          number_of_workers_started += 1
        end
      end

      logger.info("Seems like no workers were started to monitor your projects") if number_of_workers_started == 0

      # Initialize the workers
      # For now, we're not using a fancy framework that adds multiple heavy dependencies
      # including a database, etc.
      FastlaneCI::RefreshConfigDataSourcesWorker.new
    end

    # Verify that fastlane.ci is already set up on this machine.
    # If that's not the case, we have to make sure to trigger the initial clone
    def self.trigger_initial_ci_setup
      logger.info("No config repo cloned yet, doing that now")

      # This happens on the first launch of CI
      # We don't have access to the config directory yet
      # So we'll use ENV variables that are used for the initial clone only
      #
      # Long term, we'll have a nice onboarding flow, where you can enter those credentials
      # as part of a web UI. But for containers (e.g. Google Cloud App Engine)
      # we'll have to support ENV variables also, for the initial clone, so that's the code below
      # Clone the repo, and login the user
      provider_credential = GitHubProviderCredential.new(email: ENV["FASTLANE_CI_INITIAL_CLONE_EMAIL"],
                                                       api_token: ENV["FASTLANE_CI_INITIAL_CLONE_API_TOKEN"])
      # Trigger the initial clone
      FastlaneCI::ProjectService.new(
        project_data_source: FastlaneCI::JSONProjectDataSource.create(ci_config_repo,
                                                                      git_repo_config: ci_config_repo,
                                                                      provider_credential: provider_credential)
      )
      logger.info("Successfully did the initial clone on this machine")
    rescue StandardError => ex
      logger.error("Something went wrong on the initial clone")

      if ENV["FASTLANE_CI_INITIAL_CLONE_API_TOKEN"].to_s.length == 0 || ENV["FASTLANE_CI_INITIAL_CLONE_EMAIL"].to_s.length == 0
        logger.error("Make sure to provide your `FASTLANE_CI_INITIAL_CLONE_EMAIL` and `FASTLANE_CI_INITIAL_CLONE_API_TOKEN` ENV variables")
      end

      raise ex
    end
  end
end
