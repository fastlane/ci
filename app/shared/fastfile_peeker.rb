require_relative "fastfile_finder"

require "fastfile_parser"
require "digest"

module FastlaneCI
  # Utility class designed for retrieving the Fastfile's information for a given repo.
  class FastfilePeeker
    class << self
      # For a given repo, and some state associated with it (a branch or a commit sha) retrieve the FastfileParser
      # instance and return it.
      # @param [GitRepo] git_repo
      # @param [String, nil] branch
      # @param [String, nil] sha
      # @return [Fastlane::FastfileParser]
      def peek(git_repo: nil, branch: nil, sha: nil)
        git_repo.fetch(use_global_git_mutex: false)
        if branch && !branch.empty?
          # This perform the checkout of the latest commit in the branch.
          git_repo.checkout_branch(branch: branch, use_global_git_mutex: false)
        elsif sha && !sha.empty?
          git_repo.chekout_commit(sha: sha, use_global_git_mutex: false)
        else
          raise "Invalid branch or sha were provided"
        end
        # To look up for the Fastfile in the given repo directory, we make use of the
        # FastfileFinder as a global utility to find a Fastfile given a repo or a root path.
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
