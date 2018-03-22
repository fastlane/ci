require_relative "../../taskqueue/task_queue"
require "json"
require "pathname"

module FastlaneCI
  # Provides operations to create and mutate the FastlaneCI configuration
  # repository
  module ConfigurationRepositoryService
    include FastlaneCI::Logging

    class << self
      def fastlane_ci_config
        return "fastlane-ci-config"
      end
    end

    attr_reader :client

    attr_accessor :provider_credential

    def git
      @git ||= clone
    end

    # Creates a remote repository if it does not already exist, complete with
    # the expected remote files `user.json` and `projects.json`
    def create_private_remote_configuration_repo
      not_implemented(__method__)
    end

    # Returns `true` if the configuration repository is in proper format:
    #
    #   i.   The repository exists
    #   ii.  The `users.json` file exists and is a JSON array
    #   iii. The `projects.json` file exists and is a JSON array
    #
    # @return [Boolean]
    def configuration_repository_valid?
      not_implemented(__method__)
    end

    # Returns `true` if the remote configuration repository exists
    #
    # @return [Boolean]
    def configuration_repository_exists?
      not_implemented(__method__)
    end

    def clone(path: self.ci_repo_root_path, branch: nil)
      # This triggers the check of an existing repo in the given path,
      # we recover from the error making the clone and checkout
      git = Git.open(File.join(path, ConfigurationRepositoryService.fastlane_ci_config))
      return git
    rescue ArgumentError
      git = @code_hosting_service_class.clone(
        repo_url: FastlaneCI.env.repo_url,
        provider_credential: self.provider_credential,
        path: path,
        branch: branch,
        name: "fastlane-ci-config"
      )
      return git
    end

    def pull(path: self.ci_repo_root_path, branch: nil)
      auth_key = @code_hosting_service_class.setup_auth(
        repo_url: FastlaneCI.env.repo_url,
        provider_credential: self.provider_credential,
        path: @code_hosting_service_class.temp_path
      )
      git = Git.open(File.join(path, ConfigurationRepositoryService.fastlane_ci_config))
      git.fetch
      # Are we behind remote? If so, pull.
      return if git.log.between(git.branch.name, git.remote.branch.name).size.zero?
      git.pull
    rescue ArgumentError
      git = self.clone(path: path, branch: branch)
      return if git.log.between(git.branch.name, git.remote.branch.name).size.zero?
      git.pull
    ensure
      @code_hosting_service_class.unset_auth(auth_key)
    end

    # Adds (if needed) and commits a single file of the ci-config repository.
    # @params [Base::Git] git
    # @params [String] file_path
    def commit(git: self.git, file_path: nil)
      raise "file_path is mandatory" if file_path.nil?
      path = Pathname.new(file_path)
      git.add(path.to_s)
      git.commit("Changes on #{path.basename}")
    rescue Git::GitExecuteError => ex
      # This happens when you've already added or committed the selected change.
      logger.error(ex)
    end

    # Pushes the changes (if any) of the ci-config repository.
    # @params [Base::Git] git
    def push(git: self.git)
      return if git.log.between(git.remote.branch.name, git.branch.name).size.zero?
      auth_key = @code_hosting_service_class.setup_auth(
        repo_url: FastlaneCI.env.repo_url,
        provider_credential: self.provider_credential,
        path: @code_hosting_service_class.temp_path
      )
      git.push
      logger.info("Pushed changes to ci-config repo")
      @code_hosting_service_class.unset_auth(auth_key)
    end

    def file_path(file_path)
      File.join(self.ci_repo_root_path, ConfigurationRepositoryService.fastlane_ci_config, file_path)
    end

    protected

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
              email: FastlaneCI.env.initial_clone_email,
              api_token: FastlaneCI.env.clone_user_api_token,
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
      not_implemented(__method__)
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
      not_implemented(__method__)
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

    # The containing path of the ci-config repository.
    # @return [String]
    def ci_repo_root_path
      path = File.expand_path(File.join("~/.fastlane", "ci"))
      FileUtils.mkdir_p(path) unless File.directory?(path)
      return path
    end
  end
end
