require_relative "../../shared/json_convertible"

module FastlaneCI
  # Information that is required for us to be able to checkout a branch/sha from a fork
  # This information is also stored together with `FastlaneCI::Build`
  class GitForkConfig
    # The `include` below shouldn't be here, as it already is part of JSONBuildDataSource
    # however not having this line here, will not properly persist those objects
    # This might be related to the order in which the files are imported. Probably
    # worth investigating at some point, but not critical
    include FastlaneCI::JSONConvertible

    # @return [String] e.g. "https://github.com/fastlane/ci"
    attr_reader :clone_url

    # @return [String] e.g. "master"
    attr_reader :branch

    # @return [String] e.g. "new-topic", "pull/123/head"
    #   sometimes we have a ref we can use, in that case, we don't need to pull a fork
    attr_reader :ref

    # @return [String] e.g. "a690bef20006f3b7ddbafbe65408c516da077d3f"
    attr_reader :sha

    # If you have a ref you can pass, e.g.: `pull/661/head`, that's preferred
    def initialize(sha: nil, branch: nil, clone_url: nil, ref: nil)
      @sha = sha
      @branch = branch
      @clone_url = clone_url
      @ref = ref
    end
  end
end
