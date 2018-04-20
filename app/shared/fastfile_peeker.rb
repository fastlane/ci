require_relative "fastfile_finder"
require_relative "github_handler"
require_relative "logging_module"

require "fastfile_parser"
require "digest"

module FastlaneCI
  # Object that encapsulates retrieving Fastfile information for a given repo.
  class FastfilePeeker
    include FastlaneCI::GitHubHandler
    include FastlaneCI::Logging

    def initialize(provider_credential: nil, notification_service: nil)
      @provider_credential = provider_credential
      @notification_service = notification_service
      @client = Octokit::Client.new(access_token: @provider_credential.api_token)
    end

    def fastfile(repo_config:, sha_or_branch:)
      fastfile_parser = fastfile_from_github(
        repo_full_name: repo_config.full_name,
        sha_or_branch: sha_or_branch
      )
      if fastfile_parser.nil?
        logger.debug("Checking out repo and searching for fastfile in #{repo_config.full_name}")
        fastfile_parser = fastfile_from_repo(repo_config: repo_config, branch: sha_or_branch)
      end
      return fastfile_parser
    end

    # For a given repo, and some state associated with it (a branch or a commit sha) retrieve the FastfileParser
    # instance and return it.
    # @param [GitRepo] git_repo
    # @param [String, nil] branch
    # @param [String, nil] sha
    # @return [Fastlane::FastfileParser]
    def fastfile_from_repo(repo_config: nil, branch: nil, sha: nil)
      git_repo = FastlaneCI::GitRepo.new(
        git_config: repo_config,
        local_folder: Dir.mktmpdir,
        provider_credential: @provider_credential,
        async_start: false,
        notification_service: @notification_service
      )
      git_repo.fetch

      if branch && !branch.empty?
        # This performs the checkout of the latest commit in the branch.
        git_repo.checkout_branch(branch: branch)
      elsif sha && !sha.empty?
        git_repo.chekout_commit(sha: sha)
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
        raise "No Fastfile found in #{git_repo.local_folder}"
      end
    end

    private

    def fastfile_from_contents_map(contents_map)
      github_action(@client) do |_client|
        return nil if contents_map.nil?

        if contents_map
          content = contents_map[:content]
          return contents_map[:encoding] == "base64" ? Base64.decode64(content) : content
        end
        return nil
      end
    end

    def remote_paths(repo_full_name:, sha_or_branch:)
      github_action(@client) do
        begin
          logger.debug("Checking for fastfile in #{repo_full_name}")
          result = @client.tree(repo_full_name, sha_or_branch, { recursive: true })
          return result[:tree].map { |resource| resource[:path] } || []
        rescue Octokit::NotFound
          return []
        end
      end
    end

    def remote_file_contents_map(repo_full_name: nil, sha_or_branch:, path:)
      github_action(@client) do |client|
        begin
          logger.debug("Checking for fastfile in #{repo_full_name}/fastlane/Fastfile")
          contents_map = client.contents(repo_full_name, path: path, ref: sha_or_branch)
          return contents_map
        rescue Octokit::NotFound
          return nil
        end
      end
    end

    def fastfile_from_github(repo_full_name: nil, sha_or_branch:)
      paths = remote_paths(repo_full_name: repo_full_name, sha_or_branch: sha_or_branch)

      fastfile_path = FastfileFinder.find_prioritary_fastfile_path(paths: paths)

      contents_map = remote_file_contents_map(
        repo_full_name: repo_full_name,
        sha_or_branch: sha_or_branch,
        path: fastfile_path
      )
      contents = fastfile_from_contents_map(contents_map)

      return Fastlane::FastfileParser.new(file_content: contents)
    end
  end
end
