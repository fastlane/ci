module FastlaneCI
  # Encapsulates the data we need to know how to checkout a branch from a fork
  # We can probably use this for all the things, though.

  # Example data
  # => #<FastlaneCI::GitHubOpenPR:0x007f9b65c20990
  #         @branch="joshdholtz-allow-xcodebuild-build-settings-to-use-inherit",
  #         @clone_url="https://github.com/fastlane/fastlane.git",
  #         @current_sha="a0a97c934174474fe7b8c87837eb0176f1723d1d",
  #         @number=12443,
  #         @repo_full_name="fastlane/fastlane">
  #
  class GitHubOpenPR
    # @return [String]: The URL to clone the repo for this PR
    attr_reader :clone_url

    # @return [String]: The branch that is used for this particular PR
    attr_reader :branch

    # @return [String]: The full nume (slug) of the repo (e.g. "fastlane/ci")
    attr_reader :repo_full_name

    # @return [Number]: The number of this particular GitHub PR
    attr_reader :number

    # @return [String]: The SHA for the most recent commit for this PR
    attr_reader :current_sha

    def initialize(current_sha:, branch:, repo_full_name:, number:, clone_url:)
      @current_sha = current_sha
      @branch = branch
      @repo_full_name = repo_full_name
      @number = number
      @clone_url = clone_url
    end

    def fork_of_repo?(repo_full_name:)
      return self.repo_full_name != repo_full_name
    end

    def git_ref
      return number.nil? ? nil : "pull/#{number}/head"
    end
  end
end
