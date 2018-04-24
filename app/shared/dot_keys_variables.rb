# frozen_string_literal: true

module FastlaneCI
  # Class wrapping fastlane CI environment variables that people using fastlane.ci should care about
  # NOTE: This doesn't include the fastlane.ci-developer-sepcific environment variables primarily used
  # during development of fastlane.ci by the fastlane
  class DotKeysVariables
    # @return [Hash]
    def all
      {
        ci_base_url: ci_base_url,
        encryption_key: encryption_key,
        ci_user_password: ci_user_password,
        ci_user_api_token: ci_user_api_token,
        repo_url: repo_url,
        initial_onboarding_user_api_token: initial_onboarding_user_api_token
      }
    end

    # used to construct build output links in PR statuses back to fastlane.ci build page
    def ci_base_url
      # Assume we're in dev if we don't have this url
      return ENV["FASTLANE_CI_BASE_URL"] || "http://localhost:8080"
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
    def initial_onboarding_user_api_token
      ENV["FASTLANE_CI_INITIAL_ONBOARDING_USER_API_TOKEN"]
    end
  end
end
