require "json"
require_relative "../shared/logging_module"
require_relative "../shared/github_handler"

module FastlaneCI
  # Provides operations to create and mutate the FastlaneCI configuration
  # repository
  class ConfigurationRepositoryService
    include FastlaneCI::Logging
    include FastlaneCI::GitHubHandler

    # @return [Octokit::Client]
    attr_reader :client

    # Instantiates new `ConfigurationRepositoryService` class
    #
    # @param  [ProviderCredential] provider_credential
    def initialize(provider_credential: nil)
      @client = Octokit::Client.new(access_token: provider_credential.api_token)
    end

    # Creates a remote repository if it does not already exist, complete with
    # the expected remote files `user.json` and `projects.json`
    def create_private_remote_configuration_repo
      github_action(client) do
        # TODO: Handle the common case of when provided account can't create a new private repo
        client.create_repository(repo_name, private: true) unless configuration_repository_exists?
        create_remote_json_file("users.json", json_string: serialized_users)
        create_remote_json_file("projects.json")
        create_remote_json_file("environment.json")
      end
    end

    # Returns `true` if the configuration repository is in proper format:
    #
    #   i.   The repository exists
    #   ii.  The `users.json` file exists and is a JSON array
    #   iii. The `projects.json` file exists and is a JSON array
    #
    # @return [Boolean]
    def configuration_repository_valid?
      # Return cached true value, if it was successful, otherwise keep checking because it might have been fixed
      return @config_repo_exists unless @config_repo_exists.nil? || (@config_repo_exists == false)

      valid = configuration_repository_exists?
      logger.debug("Configuration repo #{repo_shortform} doesn't exist") unless valid

      if valid
        valid = remote_file_a_json_array?("users.json")
        logger.debug("users.json file is not correct, it should be a json array") unless valid
      end

      if valid
        valid = remote_file_a_json_array?("projects.json")
        logger.debug("projects.json file is not correct, it should be a json array") unless valid
      end

      return valid
    end

    # Returns `true` if the remote configuration repository exists
    #
    # @return [Boolean]
    def configuration_repository_exists?
      # Return cached true value, if it was successful, otherwise keep checking because it might have been fixed
      return @config_repo_exists unless @config_repo_exists.nil? || (@config_repo_exists == false)
      github_action(client) do
        @config_repo_exists = client.repository?(repo_shortform)
      end
      return @config_repo_exists
    end

    private

    # Serializes CI user and its provider credentials to a JSON format.
    #
    # After creating the private remote configuration repository, the server
    # will stop redirecting the user to the `/configuration` page. In the
    # `/dashboard` page, there's a requirement the current user has a
    # provider credential , or it will raise an exception. By writing the
    # provider credentials to the private configuration repo for the CI User,
    # it prevents this issue
    #
    # @return [String]
    def serialized_users
      users = [
        User.new(
          email: FastlaneCI.dot_keys.ci_user_email,
          password_hash: BCrypt::Password.create(FastlaneCI.dot_keys.ci_user_password),
          provider_credentials: [
            FastlaneCI::GitHubProviderCredential.new(
              email: FastlaneCI.dot_keys.initial_clone_email,
              api_token: FastlaneCI.dot_keys.clone_user_api_token,
              full_name: "Clone User credentials"
            )
          ]
        )
      ]

      users.each do |user|
        # Fist need to serialize the provider credentials and ignore the `ci_user`
        # instance variable. The reasoning is since if you serialize the `user`
        # first, you will call `to_object_map` on the `ci_user`, which holds
        # reference to a user. This will go on indefinitely
        user.provider_credentials.map! do |credential|
          credential.to_object_dictionary(ignore_instance_variables: [:@ci_user])
        end
      end

      JSON.pretty_generate(users.map(&:to_object_dictionary))
    end

    # Creates an empty json array file in the configuration repository
    #
    # @raise  [Octokit::UnprocessableEntity] when file already exists
    # @param  [String] file_path
    def create_remote_json_file(file_path, json_string: "[]")
      github_action(client) do
        client.contents(repo_shortform, path: file_path)
      end
    rescue Octokit::NotFound
      client.create_contents(
        repo_shortform, file_path, "Add initial #{file_path}", json_string
      )
    rescue Octokit::UnprocessableEntity
      # rubocop:disable Metrics/LineLength
      logger.debug("The file #{file_path} already exists in remote configuration repo: #{repo_shortform}. Not overwriting the file.")
      # rubocop:enable Metrics/LineLength
    end

    #####################################################
    # @!group Boolean Helpers
    #####################################################

    # Configuration will fail if the `file_path` file contents are not a
    # JSON array
    #
    # @param  [String] file_path
    # @raise  [JSON::ParserError] if the JSON in the file contents is not valid
    # @raise  [Octokit::NotFound] if the file_path is not found
    # @return [Boolean]
    def remote_file_a_json_array?(file_path)
      return false unless configuration_repository_exists?
      logger.debug("Checking that #{repo_shortform}/#{file_path} is a json array")

      contents_map = {}
      github_action(client) do
        contents_map = client.contents(repo_shortform, path: file_path)
      end
      contents_json =
        contents_map[:encoding] == "base64" ? Base64.decode64(contents_map[:content]) : contents_map[:content]
      contents = JSON.parse(contents_json)

      return contents.kind_of?(Array)
    rescue TypeError
      if contents.nil?
        logger.debug("#{repo_shortform}/#{file_path} has no content")
      else
        logger.debug("#{repo_shortform}/#{file_path} is type #{contents.type}, should be Array")
      end
      return false
    rescue Octokit::NotFound
      logger.debug("#{repo_shortform}/#{file_path} couldn't be found")
      return false
    rescue JSON::ParserError
      logger.debug("#{repo_shortform}/#{file_path} couldn't be json-parsed, object type: #{contents.type}")
      return false
    end

    ####################################################
    # @!group String Helpers
    #####################################################

    # The name of the configuration repository URL `repo`
    #
    # @return [String]
    def repo_name
      return "" unless FastlaneCI.dot_keys.repo_url
      return FastlaneCI.dot_keys.repo_url.split("/").last
    end

    # The short-form of the configuration repository URL `ueser/repo`
    #
    # @return [String]
    def repo_shortform
      return "" unless FastlaneCI.dot_keys.repo_url
      return FastlaneCI.dot_keys.repo_url.split("/").last(2).join("/")
    end
  end
end
