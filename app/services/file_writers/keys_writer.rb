# frozen_string_literal: true

require_relative "file_writer"

module FastlaneCI
  # A file writer for the `.keys` configuration file, containing environment
  # variables needed by FastlaneCI
  class KeysWriter < FileWriter
    # @return [String]
    def file_template
      return <<~FILE
        # Randomly generated key, that's used to encrypt the user passwords
        FASTLANE_CI_ENCRYPTION_KEY='#{locals[:encryption_key]}'

        # The password for your CI bot account
        FASTLANE_CI_PASSWORD='#{locals[:ci_user_password]}'

        # The API token of your fastlane CI bot account
        FASTLANE_CI_BOT_API_TOKEN='#{locals[:ci_user_api_token]}'

        # The git URL (https) for the configuration repo
        FASTLANE_CI_REPO_URL='#{locals[:repo_url]}'

        # The API token for initial onboarding. It's responsible for creating
        # the remote `fastlane.ci` configuration repository, and inviting the
        # bot user to the corresponding repository so it may perform actions on
        # it
        FASTLANE_CI_INITIAL_ONBOARDING_USER_API_TOKEN='#{locals[:initial_onboarding_user_api_token]}'
      FILE
    end
  end
end
