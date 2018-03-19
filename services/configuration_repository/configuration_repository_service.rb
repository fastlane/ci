require_relative "../../taskqueue/task_queue"
require "json"
require "pathname"

module FastlaneCI
  # Provides operations to create and mutate the FastlaneCI configuration
  # repository
  module ConfigurationRepositoryService
    include FastlaneCI::Logging

    # rubocop:disable Style/ClassVars
    @@mutex = Mutex.new

    def self.mutex
      return @@mutex
    end
    # rubocop:enable Style/ClassVars

    def self.fastlane_ci_config
      return "fastlane-ci-config"
    end

    attr_reader :client

    attr_accessor :provider_credential

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
      self.watch_for_changes!(git, path) if File.directory?(path)
      return git
    rescue ArgumentError
      git = @code_hosting_service_class.clone(
        repo_url: FastlaneCI.env.repo_url,
        provider_credential: self.provider_credential,
        path: path,
        branch: branch,
        name: "fastlane-ci-config"
      )
      self.watch_for_changes!(git, path) if File.directory?(path)
      return git
    end

    def pull(path: self.ci_repo_root_path, branch: nil)
      git = Git.open(File.join(path, ConfigurationRepositoryService.fastlane_ci_config))
      git.fetch
      # Are we behind remote? If so, pull.
      return if git.log.between(git.branch.name, git.remote.branch.name).size.zero?
      git.pull
    rescue ArgumentError
      git = self.clone(path: path, branch: branch)
      return if git.log.between(git.branch.name, git.remote.branch.name).size.zero?
      git.pull
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

    # This method starts the watching of the ci-config repo folder changes
    # so we can report every file being changed in a real-time basis.
    # @param [Git::Base] git
    # @param [String] path, the path of the repo which changes are being watched.
    def watch_for_changes!(git, path)
      require "ruby-watchman"
      require "socket"
      sockname = RubyWatchman.load(
        `watchman --output-encoding=bser get-sockname`
      )["sockname"]
      raise unless $?.exitstatus.zero?

      unwatch_changes unless @socket.nil?

      @socket = UNIXSocket.open(sockname) do |socket|
        root = Pathname.new(path).realpath.to_s
        roots = RubyWatchman.query(["watch-list"], socket)["roots"]
        unless roots.include?(root)
          # this path isn't being watched yet; try to set up watch
          result = RubyWatchman.query(["watch", root], socket)

          # root_restrict_files setting may prevent Watchman from working
          raise if result.key?("error")
        end

        query = ["query", root, {
        "expression" => ["anyof",
                         ["match", "**/*.json", "wholename", { "includedotfiles" => false }]],
          "fields" => ["name"]
        }]
        paths = RubyWatchman.query(query, socket)

        # could return error if watch is removed
        raise if paths.key?("error")

        unless ConfigurationRepositoryService.mutex.locked?
          ConfigurationRepositoryService.mutex.synchronize do
            handle_repo_changes(git, paths["files"])
          end
        end
      end
    end

    def unwatch_changes
      `watchman shutdown-server`
      @socket&.close
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

    # The method that makes the necessary changes over the files being watched in a given repo.
    # TODO: For now, until https://github.com/fastlane/ci/pull/311 is solved, we take the local
    # changes as source of truth by force pushing changes made. Ideally, this shouldn't be needed
    # if we never encounter a situation where there are conflicts with the remote.
    # @param [Git::Base] git, the ci-config repo.
    # @param [Array<String>] files, directories for files being changed.
    def handle_repo_changes(git, files)
      # For every file change, we make a different commit, in order to make a fine grained commit history.
      # Obviously, all files in .git path are rejected by default.
      return if files.empty?

      files.map { |file| Pathname.new(file) }.each do |file|
        path = Pathname.new(file)
        next unless git.status.deleted.assoc(path.basename)&.count.try(:>, 0) || git.status.added.assoc(path.basename)&.count.try(:>, 0) || git.status.changed.assoc(path.basename)&.count.try(:>, 0) || git.status.untracked.assoc(path.basename)&.count.try(:>, 0)
        begin
          git.add(path.to_s)
          git.commit("Changes on #{path.basename}")
        rescue Git::GitExecuteError
          # This is caused when the file is already added and/or commited.
          # So we gracefully continue with the execution
        end
      end
      return if git.log.between(git.remote.branch.name, git.branch.name).size.zero?
      @code_hosting_service_class.setup_auth(
        repo_url: FastlaneCI.env.repo_url,
        provider_credential: self.provider_credential,
        path: @code_hosting_service_class.temp_path
      )
      git.push
      logger.info("Pushed changes to ci-config repo")
      @code_hosting_service_class.unset_auth
    end
  end
end
