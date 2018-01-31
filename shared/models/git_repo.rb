# We're using https://github.com/ruby-git/ruby-git
# for all git interactions
require "git"
require "tty-command"
require "securerandom"
require_relative "../logging_module"

module FastlaneCI
  # Encapsulates all the data that is needed by GitRepo
  # We can have various provider_credentials, but they all need to be turned into `GitRepoAuth`s
  # This is because different git providers can have different needs for data
  # What github needs is an `api_token`, but a local git repo might only need a `password`.
  # We'll call both of these "auth_tokens" here, this way we can use GitRepoAuth
  # as a way to unify those, and prevent overloading names at the data source.
  # Otherwise, in the JSON we'd see "password" but for some repos that might be an auth_token, or an api_token, or password
  class GitRepoAuth
    attr_accessor :remote_host # in the case of github, this is usually `github.com`
    attr_accessor :username    # whatever the git repo needs for a username, usually just an email, usually CI
    attr_accessor :full_name   # whatever the git repo needs for a username, usually just an email, usually fastlane.CI
    attr_accessor :auth_token  # usually an API key, but could be a password, usually fastlane.CI's auth_token
    def initialize(remote_host: nil, username: nil, full_name: nil, auth_token: nil)
      @remote_host = remote_host
      @username = username
      @full_name = full_name
      @auth_token = auth_token
    end
  end

  # Responsible for managing git repos
  # This includes the configs repo, but also the actual source code repos
  # This class makes sure to use the right credentials, does proper cloning,
  # pulling, pushing, git commit messages, etc.
  # TODO: @josh: do we need to move this somewhere? We only want to support git
  #   so no need to have super class, etc, right?
  class GitRepo
    include FastlaneCI::Logging

    # @return [GitRepoConfig]
    attr_accessor :git_config
    # @return [GitRepoAuth]
    attr_accessor :repo_auth # whatever pieces of information that can change between git users

    def initialize(git_config: nil, provider_credential: nil)
      self.validate_initialization_params!(git_config: git_config, provider_credential: provider_credential)
      @git_config = git_config

      # Ok, so now we need to pull the bit of information from the credentials that we know we need for git repos
      case provider_credential.type
      when FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
        # Package up the authentication parts that are required
        @repo_auth = GitRepoAuth.new(
          remote_host: provider_credential.remote_host,
          username: provider_credential.email,
          full_name: provider_credential.full_name,
          auth_token: provider_credential.api_token
        )
      else
        # if we add another ProviderCredential type, we'll need to figure out what parts of the credential go where
        raise "unsupported credential type: #{provider_credential.type}"
      end

      if File.directory?(self.git_config.local_repo_path)
        # TODO: test if this crashes if it's not a git directory
        repo = Git.open(self.git_config.local_repo_path)
        if repo.index.writable?
          # Things are looking legit so far
          # Now we have to check if the repo is actually from the
          # same repo URL
          if repo.remote("origin").url.casecmp(self.git_config.git_url.downcase).zero?
            self.git.reset_hard
            self.pull
          else
            logger.debug("[#{self.git_config.id}] Repo URL seems to have changed... deleting the old directory and cloning again")
            clear_directory
            self.clone
          end
        else
          clear_directory
          self.clone
        end
      else
        self.clone
      end
      logger.debug("Using #{self.git_config.local_repo_path} for config repo")
    end

    # This is where we store the local git repo
    # fastlane.ci will also delete this directory if it breaks
    # and just re-clones. So make sure it's fine if it gets deleted
    def containing_path
      self.git_config.containing_path
    end

    def validate_initialization_params!(git_config: nil, provider_credential: nil)
      raise "No git config provided" if git_config.nil?
      raise "No provider_credential provided" if provider_credential.nil?

      credential_type = provider_credential.type
      git_config_credential_type = git_config.provider_credential_type_needed

      credential_mismatch = credential_type != git_config_credential_type
      raise "provider_credential.type and git_config.provider_credential_type_needed mismatch: #{credential_type} vs #{git_config_credential_type}" if credential_mismatch
    end

    def clear_directory
      FileUtils.rm_rf(self.git_config.local_repo_path)
    end

    # Returns the absolute path to a file from inside the git repo
    def file_path(file_path)
      File.join(self.git_config.local_repo_path, file_path)
    end

    def git
      if @_git.nil?
        @_git = Git.open(self.git_config.local_repo_path)
      end

      return @_git
    end

    # Return the last commit, that isn't a merge commit
    # Make sure to have checked out the right branch for which
    # you want to get the last commit of
    def most_recent_commit
      self.git.log.each do |commit|
        # 2 parents only happen on merge commits https://stackoverflow.com/a/3824122
        return commit unless commit.parents.count >= 2
      end
      return nil
    end

    # Responsible for setting the author information when committing a change
    def setup_author(full_name: self.repo_auth.full_name, username: self.repo_auth.username)
      # TODO: performance implications of settings this every time?
      # TODO: Set actual name + email here
      # TODO: see if we can set credentials here also
      logger.debug("Using #{full_name} with #{username} as author information")
      git.config("user.name", full_name)
      git.config("user.email", username)
    end

    def temporary_git_storage
      @temporary_git_storage ||= File.expand_path("~/.fastlane/.tmp")
      FileUtils.mkdir_p(@temporary_git_storage)
      return @temporary_git_storage
    end

    # Responsible for using the auth token to be able to push/pull changes
    # from git remote
    def setup_auth(repo_auth: self.repo_auth)
      # More details: https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage
      storage_path = File.join(self.temporary_git_storage, "git-auth-#{SecureRandom.uuid}")

      local_repo_path = self.git_config.local_repo_path
      FileUtils.mkdir_p(local_repo_path) unless File.directory?(local_repo_path)

      store_credentials_command = "git credential-store --file #{storage_path.shellescape} store"
      content = [
        "protocol=https",
        "host=#{repo_auth.remote_host}",
        "username=#{repo_auth.username}",
        "password=#{repo_auth.auth_token}",
        ""
      ].join("\n")

      scope = "local"

      unless File.directory?(File.join(local_repo_path, ".git"))
        # we don't have a git repo yet, we have no choice
        # TODO: check if we find a better way for the initial clone to work without setting system global state
        scope = "global"
      end
      use_credentials_command = "git config --#{scope} credential.helper 'store --file #{storage_path.shellescape}'"

      Dir.chdir(local_repo_path) do
        cmd = TTY::Command.new(printer: :quiet)
        cmd.run(store_credentials_command, input: content)
        cmd.run(use_credentials_command)
      end

      return storage_path
    end

    def unset_auth(storage_path: nil)
      return unless storage_path.kind_of?(String)
      # TODO: Also auto-clean those files from time to time, on server re-launch maybe, or background worker
      FileUtils.rm(storage_path) if File.exist?(storage_path)
    end

    def pull(repo_auth: self.repo_auth)
      if ENV["FASTLANE_EXTRA_VERBOSE"] # because this repeats a ton
        logger.debug("[#{self.git_config.id}]: Pulling latest changes")
      end
      storage_path = self.setup_auth(repo_auth: repo_auth)
      git.pull
    ensure
      unset_auth(storage_path: storage_path)
    end

    # This method commits and pushes all changes
    # if `file_to_commit` is `nil`, all files will be added
    # TODO: this method isn't actually tested yet
    def commit_changes!(commit_message: nil, file_to_commit: nil, repo_auth: self.repo_auth)
      raise "file_to_commit not yet implemented" if file_to_commit
      commit_message ||= "Automatic commit by fastlane.ci"

      self.setup_author(full_name: repo_auth.full_name, username: repo_auth.username)

      git.add(all: true) # TODO: for now we only add all files
      git.commit(commit_message)
      git.push
    end

    def push(repo_auth: self.repo_auth)
      self.setup_author(full_name: repo_auth.full_name, username: repo_auth.username)
      storage_path = self.setup_auth(repo_auth: repo_auth)
      logger.debug("Pushing git repo....")

      # TODO: how do we handle branches
      self.git.push
    ensure
      unset_auth(storage_path: storage_path)
    end

    def status
      self.git.status
    end

    # Discard any changes
    def reset_hard!
      self.git.reset_hard
    end

    def clone(repo_auth: self.repo_auth)
      raise "No containing path available" unless self.containing_path
      logger.debug("Cloning git repo #{self.git_config.git_url}....")

      storage_path = self.setup_auth(repo_auth: repo_auth)
      logger.debug("[#{self.git_config.id}]: Cloning git repo #{self.git_config.git_url}")
      Git.clone(self.git_config.git_url, self.git_config.id,
                path: self.containing_path,
                recursive: true)
    ensure
      unset_auth(storage_path: storage_path)
    end
  end
end
