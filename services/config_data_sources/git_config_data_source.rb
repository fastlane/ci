require_relative "config_data_source"

module FastlaneCI
  # (default) Store configuration in git
  class GitConfigDataSource < DataSource
    attr_accessor :git_url

    def initialize(git_url: nil)
      raise "No git_url provided" if git_url.to_s.length == 0

      self.git_url = git_url

      setup_repo
    end

    # Access configuration
    def projects
      path = file_path("projects.json")
      return [] unless File.exist?(path)
      return JSON.parse(File.read(path))
    end

    def projects=(projects)
      File.write(file_path("projects.json"), JSON.pretty_generate(projects))
      commit_changes!
    end

    # Helper methods

    # Clones the repo if necessary
    # Pulls the latest changes from remote repo
    def setup_repo
      if File.directory?(local_git_directory)
        if File.directory?(File.join(local_git_directory, ".git"))
          Dir.chdir(local_git_directory) do
            FastlaneApp::CMD.run("git pull")
          end
        else
          # directory exists, but no git directory
          # clear the old directory and re-clone
          FileUtils.rm_rf(local_git_directory)
          setup_repo
        end
      else
        FastlaneApp::CMD.run("git clone", self.git_url, local_git_directory)
      end
    end

    # This is where we store the local git repo
    # fastlane.ci will also delete this directory if it breaks
    # and just re-clones. So make sure it's fine if it gets deleted
    def local_git_directory
      # TODO: fallback to use /tmp if we don't have the permission to write to this directory
      return File.expand_path("~/.fastlane/ci/")
    end

    private

    def file_path(path)
      File.join(local_git_directory, path)
    end

    def commit_changes!
      Dir.chdir(local_git_directory) do
        FastlaneApp::CMD.run("git add -A")
        FastlaneApp::CMD.run("git commit -m", commit_message)
        FastlaneApp::CMD.run("git push")
      end
    end

    def commit_message
      "Automatic commit by fastlane.ci"
    end
  end
end
