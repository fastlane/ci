require_relative "./code_hosting/git_hub_service"
require_relative "./config_data_sources/json_project_data_source"
require_relative "./config_service"
require_relative "./configuration_repository/configuration_repository_service"
require_relative "./configuration_repository/github_configuration_repository_service"
require_relative "./data_sources/json_build_data_source"
require_relative "./data_sources/json_user_data_source"
require_relative "./environment_variable_service"
require_relative "./onboarding_service"
require_relative "./project_service"
require_relative "./notification_service"
require_relative "./user_service"
require_relative "./worker_service"

require "openssl"
require "securerandom"

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
    # Service helpers
    ########################################################

    # Get the path to where we store fastlane.ci configuration
    def self.ci_config_git_repo_path
      self.ci_config_repo.local_repo_path
    end

    # Setup the fastlane.ci GitRepoConfig
    #
    # @return [GitRepoConfig]
    def self.ci_config_repo
      @_ci_config_repo ||= GitRepoConfig.new(
        id: "fastlane-ci-config",
        git_url: FastlaneCI.env.repo_url,
        description: "Contains the fastlane.ci configuration",
        name: "fastlane-ci-config",
        hidden: true
      )
    end

    # Configuration GitRepo
    #
    # @return [Git::Base]
    def self.configuration_repository_service
      @_configuration_git_repo ||= {}

      digest_key = Digest::SHA256.digest(provider_credential.type.to_s + provider_credential.api_token)

      if !@_configuration_git_repo[digest_key].nil?
        return @_configuration_git_repo[digest_key]
      else
        case provider_credential.type
        when FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
          service = FastlaneCI::GitHubConfigurationRepositoryService.new(provider_credential: provider_credential)
          service.clone
          @_configuration_git_repo[digest_key] = service
          return @_configuration_git_repo[digest_key]
        else
          return nil
        end
      end
    end

    def self.ci_user
      # Find our fastlane.ci system user
      @_ci_user ||= Services.user_service.login(
        email: FastlaneCI.env.ci_user_email,
        password: FastlaneCI.env.ci_user_password
      )
      if @_ci_user.nil?
        raise "Could not find ci_user for current setup, or the provided ci_user_password is incorrect, please make sure a user with the email #{FastlaneCI.env.ci_user_email} exists in your users.json"
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
        email: FastlaneCI.env.initial_clone_email,
        api_token: FastlaneCI.env.clone_user_api_token
      )
    end

    ########################################################
    # Services that we provide
    ########################################################

    # Start up a ProjectService from our JSONProjectDataSource
    def self.project_service
      @_project_service ||= FastlaneCI::ProjectService.new(
        project_data_source: FastlaneCI::JSONProjectDataSource.create(ci_config_repo, user: ci_user)
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
      @_github_service ||= FastlaneCI::GitHubService
    end

    # Grab a config service that is configured for the CI user
    def self.config_service
      @_config_service ||= FastlaneCI::ConfigService.new(ci_user: ci_user)
    end

    def self.worker_service
      @_worker_service ||= FastlaneCI::WorkerService.new
    end

    def self.environment_variable_service
      @_environment_variable_service ||= FastlaneCI::EnvironmentVariableService.new
    end

    def self.provider_credential_service
      @_provider_credential_service ||= FastlaneCI::ProviderCredentialService.new
    end

    def self.onboarding_service
      @_onboarding_service ||= FastlaneCI::OnboardingService.new
    end
  end
end
