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
      File.write(file_path("projects.json"), projects.to_json)
      commit_changes!
    end

    # Helper methods

    # Clones the repo if necessary
    # Pulls the latest changes from remote repo
    def setup_repo
      if File.directory?(local_git_directory)
        Dir.chdir(local_git_directory) do
          FastlaneApp::CMD.run("git pull")
        end
      else
        FastlaneApp::CMD.run("git clone", self.git_url, local_git_directory)
      end
    end

    # This is where we store the local git repo
    def local_git_directory
      # TODO: fallback to use /tmp if we don't have the permission to write to this directory
      local_git_directory = File.expand_path("~/.fastlane/ci/")
      FileUtils.mkdir_p(local_git_directory) unless File.directory?(local_git_directory)
      return local_git_directory
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
