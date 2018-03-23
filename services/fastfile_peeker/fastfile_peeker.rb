require_relative "../../fastfile-parser/fastfile_parser"

require "digest"

module FastlaneCI
  # Utility class designed for parsing Fastfiles in a repo.
  class FastfilePeeker
    class << self
      def cache
        @cache ||= {}
        return @cache
      end

      # Class method that finds the directory for the first Fastfile found given a root_path
      # @param [String] root_path
      # @return [String, nil] the path of the Fastfile or nil if no Fastfile found.
      def fastfile_path(root_path: nil)
        fastfiles = Dir[File.join(root_path, "fastlane/Fastfile")]
        fastfiles = Dir[File.join(root_path, "**/fastlane/Fastfile")] if fastfiles.count == 0
        fastfile_path = fastfiles.first
        return fastfile_path
      end

      protected :cache, :fastfile_path

      # @param [GitRepo] git_repo
      # @param [String, nil] branch
      # @param [String, nil] sha
      # @return [Fastlane::FastfileParser]
      def peek(git_repo: nil, branch: nil, sha: nil)
        cache_key = git_repo.git_config.git_url + (branch || sha)
        hash = Digest::SHA2.hexdigest(cache_key)
        return self.cache[hash] if self.cache[hash].kind_of?(Fastlane::FastfileParser)
        git_repo.fetch
        if !branch.nil? || !branch.empty?
          # This perform the checkout of the latest commit in the branch.
          git_repo.checkout_branch(branch)
        elsif !sha.nil? || !sha.empty?
          git_repo.chekout_commit(sha)
        else
          raise "Invalid branch or sha where provided"
        end
        if (fastfile_path = self.fastfile_path(root_path: git_repo.local_folder))
          fastfile = Fastlane::FastfileParser.new(path: fastfile_path)
          self.cache[hash] = fastfile
          return fastfile
        else
          raise "Not Fastfile found at #{git_repo.local_folder}"
        end
      end
    end
  end
end
