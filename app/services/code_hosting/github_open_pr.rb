module FastlaneCI
  # Encapsulates the data we need to know how to checkout a branch from a fork
  # We can probably use this for all the things, though.
  class GitHubOpenPR
    attr_reader :clone_url
    attr_reader :branch
    attr_reader :repo_full_name
    attr_reader :current_sha

    def initialize(current_sha:, branch:, repo_full_name:, clone_url:)
      @current_sha = current_sha
      @branch = branch
      @repo_full_name = repo_full_name
      @clone_url = clone_url
    end

    def fork_of_repo?(repo_full_name:)
      return self.repo_full_name != repo_full_name
    end
  end
end
