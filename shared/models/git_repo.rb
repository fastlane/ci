require "git"
require_relative "../logging_module"

module FastlaneCI
  # This class is responsible for managing git repos
  # This includes the configs repo, but also the actual source code repos
  # This class makes sure to use the right credentials, does proper cloning,
  # pulling, pushing, git commit messages, etc.
  # TODO: @josh: do we need to move this somewhere? We only want to support git
  #   so no need to have super class, etc, right?
  class GitRepo
    include FastlaneCI::Logging

    # @return [GitRepoConfig]
    attr_accessor :git_config

    def initialize(git_config: nil)
      raise "No git config provided" if git_config.nil?
      @git_config = git_config

      if File.directory?(self.path)
        # TODO: test if this crashes if it's not a git directory
        repo = Git.open(self.path)
        if repo.index.writable?
          # Things are looking legit so far
          # Now we have to check if the repo is actually from the
          # same repo URL
          if repo.remote("origin").url == self.git_config.git_url
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
      logger.debug("Using #{path} for config repo")
    end

    def clear_directory
      FileUtils.rm_rf(self.path)
    end

    # This is where we store the local git repo
    # fastlane.ci will also delete this directory if it breaks
    # and just re-clones. So make sure it's fine if it gets deleted
    def containing_path
      # TODO: fallback to use /tmp if we don't have the permission to write to this directory
      File.expand_path("~/.fastlane/ci/")
    end

    # @return [String] Path to the actual folder
    def path
      File.join(containing_path, self.git_config.id)
    end

    # Returns the absolute path to a file from inside the git repo
    def file_path(file_path)
      File.join(self.path, file_path)
    end

    def git
      if @_git.nil?
        @_git = Git.open(self.path)
      end

      return @_git
    end

    def clone(session: nil)
      self.setup_auth(session: session)
      logger.debug("[#{self.git_config.id}]: Cloning git repo #{self.git_config.git_url}")
      Git.clone(self.git_config.git_url, self.git_config.id, path: self.containing_path)
    end

    # Responsible for setting the author information when committing a change
    def setup_author(session: nil)
      # TODO: performance implications of settings this every time?
      # TODO: Set actual name + email here
      # TODO: see if we can set credentials here also
      git.config("user.name", "Felix Krause")
      git.config("user.email", "KrauseFx@gmail.com")
    end

    # Responsible for using the auth token to be able to push/pull changes
    # from git remote
    def setup_auth(session: nil)
      # TODO
    end

    def pull
      if ENV["super_verbose"] # because this repeats a ton
        logger.debug("[#{self.git_config.id}]: Pulling latest changes")
      end
      git.pull
    end

    # This method commits and pushes all changes
    # if `file_to_commit` is `nil`, all files will be added
    # TODO: this method isn't actually tested yet
    def commit_changes!(commit_message: nil, file_to_commit: nil, session: nil)
      raise "file_to_commit not yet implemented" if file_to_commit
      commit_message ||= "Automatic commit by fastlane.ci"

      setup_auth(session: session)

      setup_author(session: session)
      git.add(all: true) # TODO: for now we only add all files
      git.commit(commit_message)
      git.push
    end
  end
end
