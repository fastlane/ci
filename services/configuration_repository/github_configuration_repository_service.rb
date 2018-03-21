require_relative "./configuration_repository_service"
require_relative "../code_hosting/git_hub_service"

require "json"
require "git"

module FastlaneCI
  # Provides access to the fastlane.ci configuration, when backed by GitHub.
  # Its reponsibilities are keep the repo up-to-date, handle conflicts and sync with remote.
  class GitHubConfigurationRepositoryService
    include FastlaneCI::ConfigurationRepositoryService

    # @return [Octokit::Client]
    attr_reader :client

    # Instantiates new `ConfigurationRepositoryService` class
    #
    # @param  [ProviderCredential] provider_credential
    def initialize(provider_credential: nil)
      raise "Invalid provider credential" unless provider_credential.type == FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
      self.provider_credential = provider_credential
      @code_hosting_service_class = FastlaneCI::GitHubService
      @client = @code_hosting_service_class.client(provider_credential.api_token)
    end

    # Creates a remote repository if it does not already exist, complete with
    # the expected remote files `user.json` and `projects.json`
    def create_private_remote_configuration_repo
      client.create_repository(repo_name, private: true) unless configuration_repository_exists?
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
      return client.repository?(repo_shortform)
    end

    protected

    # Creates an empty json array file in the configuration repository
    #
    # @raise  [Octokit::UnprocessableEntity] when file already exists
    # @param  [String] file_path
    def create_remote_json_file(file_path, json_string: "[]")
      client.contents(repo_shortform, path: file_path)
    rescue Octokit::NotFound
      client.create_contents(
        repo_shortform, file_path, "Add initial #{file_path}", json_string
      )
    rescue Octokit::UnprocessableEntity
      logger.debug(
        <<~WARNING_MESSAGE
          The file #{file_path} already exists in remote configuration repo:
          #{repo_shortform}. Not overwriting the file.
        WARNING_MESSAGE
      )
    end

    #####################################################
    # @!group Boolean Helpers
    #####################################################

    # Configuration will fail if the `file_path` file contents are not a
    # JSON array
    #
    # @param  [String] file_path
    # @return [Boolean]
    def remote_file_a_json_array?(file_path)
      return false unless configuration_repository_exists?
      logger.debug("Checking that #{repo_shortform}/#{file_path} is a json array")

      contents_map = client.contents(repo_shortform, path: file_path)
      contents_json = contents_map[:encoding] == "base64" ? Base64.decode64(contents_map[:content]) : contents_map[:content]
      contents = JSON.parse(contents_json)

      contents.kind_of?(Array)
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
  end
end
