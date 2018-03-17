require "json"
require_relative "../shared/logging_module"

module FastlaneCI
  # Provides operations to create and mutate the FastlaneCI configuration
  # repository
  class OnboardingService
    include FastlaneCI::Logging

    # Verify that fastlane.ci is already set up on this machine.
    # If that's not the case, we have to make sure to trigger the initial clone
    def trigger_initial_ci_setup
      logger.info("No config repo cloned yet, doing that now")

      # Trigger the initial clone
      FastlaneCI::ProjectService.new(
        project_data_source: FastlaneCI::JSONProjectDataSource.create(
          Services.ci_config_repo,
          git_repo_config: Services.ci_config_repo,
          provider_credential: Services.provider_credential
        )
      )
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
      unless no_missing_keys?
        logger.debug("Missing environment variables.")
        return false
      end

      unless local_configuration_repo_exists?
        logger.debug("local configuration repo doesn't exist")
        return false
      end

      unless remote_configuration_repository_valid?
        logger.debug("remote configuration repo is not valid")
        return false
      end

      return true
    end

    # @return [Boolean]
    def local_configuration_repo_exists?
      return Services.ci_config_repo.exists?
    end

    # @return [Boolean]
    def remote_configuration_repository_valid?
      return Services.configuration_repository_service.configuration_repository_valid?
    end

    private

    # @return [Boolean]
    def no_missing_keys?
      return Services.environment_variable_service.all_env_variables_non_nil?
    end
  end
end
