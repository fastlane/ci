require_relative "./code_hosting/git_hub_service"
require_relative "./config_data_sources/json_project_data_source"
require_relative "./config_service"
require_relative "./configuration_repository_service"
require_relative "./data_sources/json_build_data_source"
require_relative "./data_sources/json_user_data_source"
require_relative "./dot_keys_variable_service"
require_relative "./environment_variable_service"
require_relative "./setting_service"
require_relative "./onboarding_service"
require_relative "./project_service"
require_relative "./notification_service"
require_relative "./update_fastlane_ci_service"
require_relative "./user_service"
require_relative "./worker_service"
require_relative "./xcode_manager_service"
require_relative "./apple_id_service"

module FastlaneCI
  # A class that stores the singletones for each
  # service we provide
  class Services
    class << self
      include FastlaneCI::Logging
    end

    # Resets all the memoized services which rely on configurable environment
    # variables
    def self.reset_services!
      # TODO: we might need to trigger service shutdowns if they have any scheduled tasks
      logger.info("Reseting all services")

      # Reset service helpers
      @_ci_config_repo = nil
      @_configuration_git_repo = nil
      @_ci_user = nil
      @_provider_credential = nil
      @_bot_user_client = nil
      @_onboarding_user_client = nil

      # Reset services
      @_project_service = nil
      @_user_service = nil
      @_notification_service = nil
      @_build_service = nil
      @_github_service = nil
      @_config_service = nil
      @_worker_service = nil
      @_configuration_repository_service = nil
      @_update_fastlane_ci_service = nil
      @_environment_variable_service = nil
      @_setting_service = nil
      @_dot_keys_variable_service = nil
      @_xcode_manager_service = nil
      @_apple_id_service = nil
    end

    ########################################################
    # Service helpers
    ########################################################

    # Get the path to where we store fastlane.ci configuration
    def self.ci_config_git_repo_path
      # TODO: Probably shouldn't hardcode this?
      return File.expand_path("~/.fastlane/ci/fastlane-ci-config")
    end

    # Setup the fastlane.ci GitHubRepoConfig
    #
    # @return [GitHubRepoConfig]
    def self.ci_config_repo
      @_ci_config_repo ||= GitHubRepoConfig.new(
        id: "fastlane-ci-config",
        git_url: FastlaneCI.dot_keys.repo_url,
        description: "Contains the fastlane.ci configuration",
        name: "fastlane ci",
        hidden: true
      )
    end

    # Configuration GitRepo
    #
    # @return [GitRepo]
    def self.configuration_git_repo
      @_configuration_git_repo ||= FastlaneCI::GitRepo.new(
        git_config: ci_config_repo,
        provider_credential: provider_credential,
        local_folder: ci_config_git_repo_path,
        notification_service: Services.notification_service
      )
    end

    def self.ci_user
      # Find our fastlane.ci system user
      @_ci_user ||= Services.user_service.login(
        email: bot_user_client.emails.find(&:primary).email,
        password: FastlaneCI.dot_keys.ci_user_password
      )
      if @_ci_user.nil?
        raise "Could not find ci_user for current setup, or the provided ci_user_password is incorrect."
      end
      return @_ci_user
    end

    # This happens on the first launch of CI
    # We don't have access to the config directory yet
    # So we'll use ENV variables that are used for the initial clone only
    #
    # Long term, we'll have a nice onboarding flow, where you can enter those credentials
    # as part of a web UI. But for containers (e.g. Google Cloud App Engine)
    # we'll have to support ENV variables also, for the initial clone, so that's the code below
    # Clone the repo, and login the user
    #
    # @return [GitHubProviderCredential]
    def self.provider_credential
      @_provider_credential ||= GitHubProviderCredential.new(
        email: onboarding_user_client.emails.find(&:primary).email,
        api_token: FastlaneCI.dot_keys.initial_onboarding_user_api_token
      )
    end

    ########################################################
    # Services that we provide
    ########################################################

    # Start up a ProjectService from our JSONProjectDataSource
    def self.project_service
      @_project_service ||= FastlaneCI::ProjectService.new(
        project_data_source: FastlaneCI::JSONProjectDataSource.create(
          ci_config_git_repo_path,
          git_config: ci_config_repo,
          user: ci_user,
          notification_service: Services.notification_service
        )
      )
    end

    # Start up a UserService from our JSONUserDataSource
    def self.user_service
      @_user_service ||= FastlaneCI::UserService.new(
        user_data_source: FastlaneCI::JSONUserDataSource.create(ci_config_git_repo_path)
      )
    end

    # Start up a NotificationService from our JSONNotificationDataSource
    def self.notification_service
      @_notification_service ||= FastlaneCI::NotificationService.new(
        notification_data_source: JSONNotificationDataSource.create(
          File.expand_path("..", ci_config_git_repo_path)
        )
      )
    end

    # Start up the BuildService
    def self.build_service
      @_build_service ||= FastlaneCI::BuildService.new(
        build_data_source: JSONBuildDataSource.create(ci_config_git_repo_path)
      )
    end

    # Start up the BuildRunnerService
    def self.build_runner_service
      @_build_runner_service ||= FastlaneCI::BuildRunnerService.new
    end

    # @return [GithubService]
    def self.github_service
      @_github_service ||= FastlaneCI::GitHubService.new(
        provider_credential: provider_credential
      )
    end

    # Grab a config service that is configured for the CI user
    def self.config_service
      @_config_service ||= FastlaneCI::ConfigService.new(ci_user: ci_user)
    end

    def self.worker_service
      @_worker_service ||= FastlaneCI::WorkerService.new
    end

    # @return [ConfigurationRepositoryService]
    def self.configuration_repository_service
      @_configuration_repository_service ||= FastlaneCI::ConfigurationRepositoryService.new(
        provider_credential: provider_credential
      )
    end

    def self.dot_keys_variable_service
      @_dot_keys_variable_service ||= FastlaneCI::DotKeysVariableService.new
    end

    def self.xcode_manager_service
      @_xcode_manager_service ||= FastlaneCI::XcodeManagerService.new(
        user: ENV["FASTLANE_USER"] # TODO: this will be passed from settings.json via https://github.com/fastlane/ci/issues/870
      )
    end

    def self.environment_variable_service
      @_environment_variable_service ||= FastlaneCI::EnvironmentVariableService.new(
        environment_variable_data_source: JSONEnvironmentDataSource.create(ci_config_git_repo_path)
      )
    end

    def self.setting_service
      @_setting_service ||= FastlaneCI::SettingService.new(
        setting_data_source: JSONSettingDataSource.create(ci_config_git_repo_path)
      )
    end

    def self.provider_credential_service
      @_provider_credential_service ||= FastlaneCI::ProviderCredentialService.new
    end

    def self.onboarding_service
      @_onboarding_service ||= FastlaneCI::OnboardingService.new
    end

    def self.bot_user_client
      @_bot_user_client ||= Octokit::Client.new(access_token: FastlaneCI.dot_keys.ci_user_api_token)
    end

    def self.update_fastlane_ci_service
      @_update_fastlane_ci_service ||= FastlaneCI::UpdateFastlaneCIService.new
    end

    def self.onboarding_user_client
      @_onboarding_user_client ||= Octokit::Client.new(
        access_token: FastlaneCI.dot_keys.initial_onboarding_user_api_token
      )
    end

    def self.apple_id_service
      @_apple_id_service ||= FastlaneCI::AppleIDService.new(
        apple_id_data_source: JSONAppleIDDataSource.create(ci_config_git_repo_path)
      )
    end
  end
end
