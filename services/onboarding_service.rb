require "json"
require_relative "../shared/logging_module"
require_relative "../services/code_hosting/git_hub_service"

module FastlaneCI
  # Provides operations to create and mutate the FastlaneCI configuration
  # repository
  class OnboardingService
    include FastlaneCI::Logging

    # Triggers the initial clone of the remote configuration repository, to the
    # local fastlane configuration repository in `~/.fastlane/ci`
    #
    # @raise [StandardError] if the repository is not cloned successfully
    def clone_remote_repository_locally
      logger.info("No config repo cloned yet, doing that now")

      # Trigger the initial clone
      # FastlaneCI::ProjectService.new(
      #   project_data_source: FastlaneCI::JSONProjectDataSource.create(
      #     Services.ci_config_repo,
      #     git_repo_config: Services.ci_config_repo,
      #     provider_credential: Services.provider_credential
      #   )
      # )
      case Services.provider_credential.type
      when FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
        FastlaneCI::GitHubService.clone(
          repo_url: Services.ci_config_repo.git_url,
          provider_credential: Services.provider_credential,
          path: Services.ci_config_git_repo_path
        )
      end
      logger.info("Successfully did the initial clone on this machine")
    rescue StandardError => ex
      logger.error("Something went wrong on the initial clone")

      if FastlaneCI.env.clone_user_api_token.to_s.empty?
        logger.error("Make sure to provide your `FASTLANE_CI_INITIAL_CLONE_API_TOKEN` ENV variable")
      end

      raise ex
    end

    # If none of the environment variables are empty, the configuration
    # repository is valid, and the configuration repository has been cloned
    # locally, then the setup is "correct"
    #
    # @return [Boolean]
    def correct_setup?
      return required_keys_and_proper_remote_configuration_repo? &&
             local_configuration_repo_exists?
    end

    # If the user has all the required environment variables, and a valid
    # remote configuration repository, then the only thing preventing their setup
    # from being correct is cloning the repository locally. This helper function
    # is used to determine if the remote configuration repository should be
    # cloned locally on startup
    #
    # @return [Boolean]
    def required_keys_and_proper_remote_configuration_repo?
      unless no_missing_keys?
        logger.debug("Missing environment variables.")
        return false
      end

      unless remote_configuration_repository_valid?
        logger.debug("remote configuration repo is not valid")
        return false
      end

      return true
    end

    # Returns `true` if the local configuration repository exists
    #
    # @return [Boolean]
    def local_configuration_repo_exists?
      unless Services.ci_config_repo.exists?
        logger.debug("local configuration repo doesn't exist")
        return false
      end

      return true
    end

    private

    # @return [Boolean]
    def remote_configuration_repository_valid?
      return Services.configuration_repository_service.configuration_repository_valid?
    rescue NoMethodError
      return false
    end

    # @return [Boolean]
    def no_missing_keys?
      return Services.environment_variable_service.all_env_variables_non_nil?
    end
  end
end
