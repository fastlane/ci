require "json"

module FastlaneCI
  # Provides operations to create and mutate the FastlaneCI configuration
  # repository
  class ConfigurationRepositoryService
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
      return if configuration_repository_exists?
      client.create_repository(repo_name, private: true)
      create_remote_json_file("users.json", json_string: serialized_users)
      create_remote_json_file("projects.json")
    end

    # Returns `true` if the configuration repository is in proper format:
    #
    #   i.   The repository exists
    #   ii.  The `users.json` file exists and is a JSON array
    #   iii. The `projects.json` file exists and is a JSON array
    #
    # @return [Boolean]
    def configuration_repository_valid?
      configuration_repository_exists? &&
        remote_file_a_json_array?("users.json") &&
        remote_file_a_json_array?("projects.json")
    end

    # Returns `true` if the remote configuration repository exists
    #
    # @return [Boolean]
    def configuration_repository_exists?
      client.repository?(repo_shortform)
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
          email: FastlaneCI.env.ci_user_email,
          password_hash: BCrypt::Password.create(FastlaneCI.env.ci_user_password),
          provider_credentials: [
            FastlaneCI::GitHubProviderCredential.new(
              email: FastlaneCI.env.ci_user_email,
              api_token: FastlaneCI.env.ci_user_password,
              full_name: "CI User credentials"
            ),
            FastlaneCI::GitHubProviderCredential.new(
              email: FastlaneCI.env.initial_clone_email,
              api_token: FastlaneCI.env.initial_clone_api_token,
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
    # @param  [String] file_path
    def create_remote_json_file(file_path, json_string: "[]")
      client.create_contents(
        repo_shortform, file_path, "Adding #{file_path}", json_string
      )
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
      contents = JSON.parse(client.contents(repo_shortform, path: file_path))
      contents.kind_of?(Array)
    rescue TypeError
      false
    rescue Octokit::NotFound
      false
    rescue JSON::ParserError
      false
    end

    ####################################################
    # @!group String Helpers
    #####################################################

    # The name of the configuration repository URL `repo`
    #
    # @return [String]
    def repo_name
      FastlaneCI.env.repo_url.split("/").last
    end

    # The short-form of the configuration repository URL `ueser/repo`
    #
    # @return [String]
    def repo_shortform
      FastlaneCI.env.repo_url.split("/").last(2).join("/")
    end
  end
end
