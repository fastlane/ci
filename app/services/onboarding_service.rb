require "json"
require_relative "../shared/logging_module"
require_relative "../services/services"

module FastlaneCI
  # Provides operations to create and mutate the FastlaneCI configuration
  # repository
  class OnboardingService
    include FastlaneCI::Logging

    # File names that should be present in configuration repository.
    #
    # @return [Array[String]]
    CONFIGURATION_FILES = ["users.json", "projects.json"].freeze

    # Triggers the initial clone of the remote configuration repository, to the
    # local fastlane configuration repository in `~/.fastlane/ci`
    #
    # @raise [StandardError] if the repository is not cloned successfully
    def clone_remote_repository_locally
      logger.info("No config repo cloned yet, doing that now")

      # Trigger the initial clone
      Services.configuration_git_repo
      logger.info("Successfully did the initial clone on this machine")
    rescue StandardError => ex
      logger.error("Something went wrong on the initial clone")

      if FastlaneCI.dot_keys.initial_onboarding_user_api_token.to_s.empty?
        logger.error("Make sure to provide your `FASTLANE_CI_INITIAL_ONBOARDING_USER_API_TOKEN` ENV variable")
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
      return @setup_correctly unless @setup_correctly.nil?

      unless no_missing_keys?
        logger.debug("Missing environment variables.")
        return false
      end

      unless remote_configuration_repository_valid?
        logger.debug("remote configuration repo is not valid")
        return false
      end

      @setup_correctly = true
      return @setup_correctly
    end

    # Returns `true` if the local configuration repository exists, and all
    # required files are present
    # This method will only check for the really required files, most config
    # files can be generated on the fly
    #
    # @return [Boolean]
    def local_configuration_repo_exists?
      unless Dir.exist?(Services.ci_config_git_repo_path)
        logger.debug("local configuration repo doesn't exist")
        return false
      end

      configuration_repo_contents = Dir[File.join(Services.ci_config_git_repo_path, "*")]
      configuration_files = CONFIGURATION_FILES.map { |f| File.join(Services.ci_config_git_repo_path, f) }

      unless configuration_files.all? { |f| configuration_repo_contents.include?(f) }
        logger.debug("local configuration repo doesn't contain required" \
                     "configuration files: #{CONFIGURATION_FILES.join(', ')}")
        return false
      end

      return true
    end

    private

    # @return [Boolean]
    def remote_configuration_repository_valid?
      return Services.configuration_repository_service.configuration_repository_valid?
    end

    # @return [Boolean]
    def no_missing_keys?
      return Services.dot_keys_variable_service.all_dot_variables_non_nil?
    end
  end
end
