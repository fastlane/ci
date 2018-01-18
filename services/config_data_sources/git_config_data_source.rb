require_relative "config_data_source"
require_relative "../git_repo"

module FastlaneCI
  # (default) Store configuration in git
  class GitConfigDataSource
    attr_accessor :git_url

    # Reference to FastlaneCI::GitRepo
    attr_accessor :git_repo

    def initialize(git_url: nil)
      raise "No git_url provided" if git_url.to_s.length == 0

      self.git_url = git_url
      self.git_repo = FastlaneCI::GitRepo.new(
        git_url: self.git_url,
        repo_id: "fastlane-ci-config"
      )
    end

    def refresh_repo
      self.git_repo.pull
    end

    # Access configuration
    def projects
      path = self.git_repo.file_path("projects.json")
      return [] unless File.exist?(path)
      return JSON.parse(File.read(path))
    end

    def projects=(projects)
      File.write(self.git_repo.file_path("projects.json"), JSON.pretty_generate(projects))
      self.git_repo.commit_changes!
    end
  end
end
