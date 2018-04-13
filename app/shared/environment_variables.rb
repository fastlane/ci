# frozen_string_literal: true

module FastlaneCI
  # Class wrapping fastlane CI environment variables that people using fastlane.ci should care about
  # NOTE: This doesn't include the fastlane.ci-developer-sepcific environment variables primarily used
  # during development of fastlane.ci by the fastlane
  class EnvironmentVariables
    # @return [Hash]
    def all
      {
        encryption_key: encryption_key,
        ci_user_password: ci_user_password,
        ci_user_api_token: ci_user_api_token,
        repo_url: repo_url,
        clone_user_api_token: clone_user_api_token
      }
    end

    # Randomly generated key, that's used to encrypt the user passwords
    def encryption_key
      ENV["FASTLANE_CI_ENCRYPTION_KEY"]
    end

    # The password for your fastlane CI bot account
    def ci_user_password
      ENV["FASTLANE_CI_PASSWORD"]
    end

    # The API token used for the bot account
    def ci_user_api_token
      ENV["FASTLANE_CI_BOT_API_TOKEN"]
    end

    # The git URL (https) for the configuration repo
    def repo_url
      ENV["FASTLANE_CI_REPO_URL"]
    end

    # The API token used for the initial clone for the config repo
    def clone_user_api_token
      ENV["FASTLANE_CI_INITIAL_CLONE_API_TOKEN"]
    end
  end
end
