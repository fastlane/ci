# rubocop:disable Layout/EmptyLinesAroundArguments

require_relative "wizard"
require_relative "../ui/ui"

module FastlaneCI
  # A class to walk a first-time user through creating a private configuration
  # repository
  class PrivateConfigurationWizard < Wizard
    # Runs the initial configuration wizard, setting up the private GitHub
    # configuration repository
    def run!
      print_welcome_message
      print_keys_file_information
      write_keys_file
      Launch.load_dot_env
      create_remote_repo!
      print_users_json_file_information
      write_users_json_file
      print_projects_json_file_information
      write_projects_json_file
      commit_and_push_changes!
    end

    private

    #####################################################
    # @!group Messaging: show text to the user
    #####################################################

    def print_welcome_message
      UI.header("Welcome to FastlaneCI!")
      UI.message(
        <<~MESSAGE
          A mobile-optimized, self-hosted continuous integration platform.

          We've noticed this is your first time running the server. FastlaneCI
          requires some configuration information from you to properly run the
          server.
        MESSAGE
      )
    end

    def print_keys_file_information
      UI.header(".keys")
      UI.message(
        <<~MESSAGE
          FastlaneCI requires certain environment variables to be configured.
          These environment variables include:

            # Randomly generated key, that's used to encrypt the user passwords
            FASTLANE_CI_ENCRYPTION_KEY='key'

            # The email address of your fastlane CI bot account
            FASTLANE_CI_USER='email-for-your-bot-account@gmail.com'

            # The API token of your fastlane CI bot account
            FASTLANE_CI_PASSWORD='encrypted_api_password'

            # The git URL (https) for the configuration repo
            FASTLANE_CI_REPO_URL='https://github.com/username/reponame'

            # Needed just for the first startup of fastlane.ci:
            # The email address used for the intial clone for the config repo
            FASTLANE_CI_INITIAL_CLONE_EMAIL='email-for-your-clone-account@gmail.com'

            # The API token used for the initial clone for the config repo
            FASTLANE_CI_INITIAL_CLONE_API_TOKEN='api_token_for_initial_clone'
        MESSAGE
      )
    end

    def print_users_json_file_information
      UI.header("users.json")
      UI.message(
        <<~MESSAGE
          \nIn order to run fastlane.ci for the first time, the #{repo_shortform}
          needs to be populated with at least two files. The first of these
          files is the `users.json` file:

          [
            {
              "id": "auto_generated_id",
              "email": "your-name@gmail.com",
              "password_hash": "Some password hash that needs to be created.",
              "provider_credentials": [
                {
                  "email": "user-email@gmail.com",
                  "encrypted_api_token": "Encrypted GitHub API token",
                  "provider_name": "GitHub",
                  "type": "github",
                  "full_name": "Fastlane CI"
                }
              ]
            }
          ]

          The wizard will now walk you through how to generate all the required
          information:
        MESSAGE
      )
    end

    def print_projects_json_file_information
      UI.header("projects.json")
      UI.message(
        <<~MESSAGE
          \nIn order to run fastlane.ci for the first time, the #{repo_shortform}
          needs to be populated with at least two files. The second of these
          files is the `projects.json` file:

          [
            {
              "repo_config": {
                "id": "ad0dadd1-ba5a-4634-949f-0ce62b77e48f",
                "git_url": "https://github.com/your-name/fastlane-ci-demoapp",
                "full_name": "your-name/fastlane-ci-demoapp",
                "description": "Fastlane CI Demo App Repository",
                "name": "Fastlane CI Demo App",
                "provider_type_needed": "github",
                "hidden": false
              },
              "id": "db799377-aaa3-4605-ba43-c91a13c8f83",
              "project_name": "fastlane CI demo app test",
              "lane": "test",
              "enabled": true
            }
          ]
        MESSAGE
      )
    end

    #####################################################
    # @!group Writers: functions to write files
    #####################################################

    # Write .keys configuration file with proper environment variables
    def write_keys_file(encryption_key: SecureRandom.uuid)
      keys_file_path = File.join(FastlaneCI::FastlaneApp.settings.root, ".keys")
      UI.message("Writing #{keys_file_path}...")

      File.open(keys_file_path, "w") do |file|
        file.write(
          <<~FILE
            # Randomly generated key, that's used to encrypt the user passwords
            FASTLANE_CI_ENCRYPTION_KEY='#{encryption_key}'

            # The email address of your fastlane CI bot account
            FASTLANE_CI_USER='#{ci_user_email}'

            # The encrypted API token of your fastlane CI bot account
            FASTLANE_CI_PASSWORD='#{ci_user_api_token}'

            # The git URL (https) for the configuration repo
            FASTLANE_CI_REPO_URL='https://github.com/#{repo_shortform}'

            # Needed just for the first startup of fastlane.ci:
            # The email address used for the intial clone for the config repo
            FASTLANE_CI_INITIAL_CLONE_EMAIL='#{clone_user_email}'

            # The API token used for the initial clone for the config repo
            FASTLANE_CI_INITIAL_CLONE_API_TOKEN='#{clone_user_api_token}'
          FILE
        )
      end
    end

    # Writes the `users.json` file to the configuration repo
    def write_users_json_file
      users_json_file_path = configuration_git_repo.file_path("users.json")
      UI.message("Writing #{users_json_file_path}...")

      File.open(users_json_file_path, "w") do |file|
        file.write(
          <<~FILE
            [
              {
                "id": "#{SecureRandom.uuid}",
                "email": "#{ci_user_email}",
                "password_hash": "#{password_hash}",
                "provider_credentials": [
                  {
                    "email": "#{ci_user_email}",
                    "encrypted_api_token": "#{ci_user_encrypted_api_token}",
                    "provider_name": "GitHub",
                    "type": "github",
                    "full_name": "Fastlane CI"
                  }
                ]
              }
            ]
          FILE
        )
      end
    end

    # Writes the `projects.json` file to the configuration repo
    def write_projects_json_file
      projects_json_file_path = configuration_git_repo.file_path("projects.json")
      UI.message("Writing #{projects_json_file_path}...")

      File.open(projects_json_file_path, "w") do |file|
        file.write(
          <<~FILE
            [
              {
                "repo_config": {
                  "id": "#{SecureRandom.uuid}",
                  "git_url": "https://github.com/your-name/fastlane-ci-demoapp",
                  "full_name": "your-name/fastlane-ci-demoapp",
                  "description": "Fastlane CI Demo App Repository",
                  "name": "Fastlane CI Demo App",
                  "provider_type_needed": "github",
                  "hidden": false
                },
                "id": "#{SecureRandom.uuid}",
                "project_name": "fastlane CI demo app test",
                "lane": "test",
                "enabled": true
              }
            ]
          FILE
        )
      end
    end

    #####################################################
    # @!group Configuration: configuration data
    #####################################################

    # The email associated with the CI user account
    #
    # @return [String]
    def ci_user_email
      @ci_user_email ||= UI.input(
        <<~MESSAGE.rstrip
          Please enter your CI bot account email

            FASTLANE_CI_USER=
        MESSAGE
      )
    end

    # The api token associated with the CI user account
    #
    # @return [String]
    def ci_user_api_token
      @ci_user_api_token ||= UI.input(
        <<~MESSAGE.rstrip
          Please enter your CI bot account API token

            FASTLANE_CI_PASSWORD=
        MESSAGE
      )
    end

    # The email associated with the clone user account
    #
    # @return [String]
    def clone_user_email
      @clone_user_email ||= UI.input(
        <<~MESSAGE.rstrip
          Please enter your email for initial clone

            FASTLANE_CI_INITIAL_CLONE_EMAIL=
        MESSAGE
      )
    end

    # The api token associated with the clone user account
    #
    # @return [String]
    def clone_user_api_token
      @clone_user_api_token ||= UI.input(
        <<~MESSAGE.rstrip
          Please enter your api token for initial clone

            FASTLANE_CI_INITIAL_CLONE_API_TOKEN=
        MESSAGE
      )
    end

    # The git repo used for configuration in the form: `username/reponame`
    #
    # @return [String]
    def repo_shortform
      @repo_shortform ||= UI.input(
        <<~MESSAGE.rstrip
          Please enter the name for your private configuration repo:

            FASTLANE_CI_REPO_URL=https://github.com/
        MESSAGE
      )
    end

    #####################################################
    # @!group Helpers: configuration helper functions
    #####################################################

    # Creates a remote repository. If the operation is unsuccessful, the method
    # throws an exception
    #
    # @raises [StandardError]
    def create_remote_repo!
      cmd = TTY::Command.new
      output = cmd.run(
        <<~COMMAND.gsub(/\n\s+/, " ")
          curl -X POST
               -H "Authorization: token #{clone_user_api_token}"
               -d '{ "private": true, "name": "#{repo_shortform.split('/')[1]}" }'
               https://api.github.com/user/repos
        COMMAND
      )
      raise StandardError if JSON.parse(output.out)["message"] == "Bad credentials"
    end

    # Encrypted CI user api token
    #
    # @return [String]
    def ci_user_encrypted_api_token
      @ci_user_encrypted_api_token ||= begin
        new_encrypted_api_token = StringEncrypter.encode(ci_user_api_token)
        Base64.encode64(new_encrypted_api_token)
              .gsub("\r", '\\r')
              .gsub("\n", '\\n')
      end
    end

    # Returns a password hash for the CI user api token
    #
    # @return [String]
    def password_hash
      BCrypt::Password.create(ci_user_api_token)
    end

    # Encrypted CI user api token
    #
    # @return [GitRepo]
    def configuration_git_repo
      @configuration_git_repo ||= FastlaneCI::GitRepo.new(
        git_config: Launch.ci_config_repo,
        provider_credential: Launch.provider_credential
      )
    end

    # Commits the most recent changes and pushes them to the new repo
    def commit_and_push_changes!
      configuration_git_repo.commit_changes!
      configuration_git_repo.push
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundArguments
