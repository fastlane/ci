require_relative "./code_hosting/git_hub_service"
require_relative "./config_data_sources/json_project_data_source"
require_relative "./config_service"
require_relative "./configuration_repository_service"
require_relative "./data_sources/json_build_data_source"
require_relative "./data_sources/json_user_data_source"
require_relative "./environment_variable_service"
require_relative "./onboarding_service"
require_relative "./project_service"
require_relative "./notification_service"
require_relative "./user_service"
require_relative "./worker_service"

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
      @_clone_user_provider_credential = nil

      # Reset services
      @_project_service = nil
      @_user_service = nil
      @_notification_service = nil
      @_build_service = nil
      @_github_service = nil
      @_config_service = nil
      @_worker_service = nil
      @_configuration_repository_service = nil
    end

    ########################################################
    # Private Service helpers
    ########################################################

    # Get the path to where we store fastlane.ci configuration
    def self.ci_config_git_repo_path
      ci_config_repo.local_repo_path
    end

    # Setup the fastlane.ci GitRepoConfig
    #
    # @return [GitRepoConfig]
    def self.ci_config_repo
      @_ci_config_repo ||= GitRepoConfig.new(
        id: "fastlane-ci-config",
        git_url: FastlaneCI.env.repo_url,
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
        provider_credential: clone_user_provider_credential
      )
    end

    def self.ci_user
      # Find our fastlane.ci system user
      @_ci_user ||= Services.user_service.login(
        email: FastlaneCI.env.ci_user_email,
        password: FastlaneCI.env.ci_user_password,
        ci_config_repo: ci_config_repo
      )
      if @_ci_user.nil?
        raise "Could not find ci_user for current setup, please make sure a user with the email #{FastlaneCI.env.ci_user_email} exists in your users.json"
      end
      return @_ci_user
    end

    # The initial clone user's provider credential
    #
    # @return [GitHubProviderCredential]
    def self.clone_user_provider_credential
      @_clone_user_provider_credential ||= GitHubProviderCredential.new(
        email: FastlaneCI.env.initial_clone_email,
        api_token: FastlaneCI.env.clone_user_api_token
      )
    end

    # These service helper methods should not be exposed, since they become
    # global static methods, which when referenced in arbitrary classes, becomes
    # a code smell
    private_class_method :ci_config_git_repo_path, :ci_config_repo,
                         :configuration_git_repo, :ci_user,
                         :clone_user_provider_credential

    ########################################################
    # Services that we provide
    ########################################################

    # Start up a ProjectService from our JSONProjectDataSource
    def self.project_service
      @_project_service ||= FastlaneCI::ProjectService.new(
        project_data_source: FastlaneCI::JSONProjectDataSource.create(ci_config_repo, user: ci_user),
        clone_user_provider_credential: clone_user_provider_credential,
        configuration_git_repo: configuration_git_repo
      )
    end

    # Start up a UserService from our JSONUserDataSource
    def self.user_service
      @_user_service ||= FastlaneCI::UserService.new(
        user_data_source: FastlaneCI::JSONUserDataSource.create(ci_config_git_repo_path),
        configuration_git_repo: configuration_git_repo
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
        provider_credential: clone_user_provider_credential
      )
    end

    # Grab a config service that is configured for the CI user
    def self.config_service
      @_config_service ||= FastlaneCI::ConfigService.new(
        ci_user: ci_user,
        clone_user_provider_credential: clone_user_provider_credential
      )
    end

    def self.worker_service
      @_worker_service ||= FastlaneCI::WorkerService.new(
        ci_user: ci_user,
        provider_credential: clone_user_provider_credential
      )
    end

    # @return [ConfigurationRepositoryService]
    def self.configuration_repository_service
      @_configuration_repository_service ||= FastlaneCI::ConfigurationRepositoryService.new(
        provider_credential: clone_user_provider_credential
      )
    end

    def self.environment_variable_service
      @_environment_variable_service ||= FastlaneCI::EnvironmentVariableService.new
    end

    def self.provider_credential_service
      @_provider_credential_service ||= FastlaneCI::ProviderCredentialService.new
    end

    def self.onboarding_service
      @_onboarding_service ||= FastlaneCI::OnboardingService.new(
        ci_config_repo: ci_config_repo,
        clone_user_provider_credential: clone_user_provider_credential
      )
    end
  end
end
