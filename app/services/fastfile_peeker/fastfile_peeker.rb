require_relative "../../shared/fastfile_finder"

require "fastfile_parser"
require "digest"

module FastlaneCI
  # Utility class designed for parsing Fastfiles in a repo.
  class FastfilePeeker
    class << self

      # @param [GitRepo] git_repo
      # @param [String, nil] branch
      # @param [String, nil] sha
      # @return [Fastlane::FastfileParser]
      def peek(git_repo: nil, branch: nil, sha: nil)
        git_repo.fetch
        if branch && !branch.empty?
          # This perform the checkout of the latest commit in the branch.
          git_repo.checkout_branch(branch)
        elsif sha && !sha.empty?
          git_repo.chekout_commit(sha)
        else
          raise "Invalid branch or sha were provided"
        end
        fastfile_path = FastfileFinder.find_fastfile_in_repo(repo: git_repo)
        if fastfile_path
          fastfile = Fastlane::FastfileParser.new(path: fastfile_path)
          return fastfile
        else
          raise "Not Fastfile found at #{git_repo.local_folder}"
        end
      end
    end
  end
end
