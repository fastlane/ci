module FastlaneCI
  # Information that is required for us to be able to checkout a branch/sha from a fork
  # This information is also stored together with `FastlaneCI::Build`
  class GitForkConfig
    # @return [String]
    attr_reader :clone_url

    # @return [String] e.g. 
    attr_reader :branch

    # @return [String] e.g. "new-topic", "pull/123/head"
    #   sometimes we have a ref we can use, in that case, we don't need to pull a fork
    attr_reader :ref 

    # @return [String]
    attr_reader :current_sha

    # If you have a ref you can pass, e.g.: `pull/661/head`, that's preferred
    def initialize(current_sha: nil, branch:, clone_url:, ref: nil)
      @current_sha = current_sha
      @branch = branch
      @clone_url = clone_url
      @ref = ref
    end
  end
end
