module FastlaneCI
  # Information that is required for us to be able to checkout a branch/sha from a fork
  class GitForkConfig
    attr_reader :clone_url
    attr_reader :branch
    attr_reader :current_sha

    def initialize(current_sha: nil, branch:, clone_url:)
      @current_sha = current_sha
      @branch = branch
      @clone_url = clone_url
    end
  end
end
