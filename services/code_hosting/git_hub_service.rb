require_relative "code_hosting_service"
require_relative "../../shared/logging_module"

require "set"
require "octokit"
require "git"
require "addressable/uri"

module FastlaneCI
  # Data source that interacts with GitHub
  class GitHubService < CodeHostingService
    include FastlaneCI::Logging

    class << self
      attr_accessor :status_context_prefix

      def self.temp_path
        temporary_path = File.join(Dir.tmpdir, ".fastlane")
        FileUtils.mkdir_p(temporary_path) unless File.directory?(temporary_path)
        return temporary_path
      end
    end

    GitHubService.status_context_prefix = "fastlane.ci: "

    # The email is actually optional for API access
    # However we ask for the email on login, as we also plan on doing commits for the user
    # and this way we can make sure to configure things properly for git to use the email
    attr_accessor :provider_credential

    def initialize(provider_credential: nil)
      self.provider_credential = provider_credential

      @_client = Octokit::Client.new(access_token: provider_credential.api_token)
      Octokit.auto_paginate = true # TODO: just for now, we probably should do smart pagination in the future
    end

    # This method shallow clones the repo using the provider credential and looks for a valid _fastlane_
    # configuration, parses the Fastfile (if found), and returns the lanes in the following way:
    #     { 
    #       :ios => [:lane_name, :other_lane_name],
    #       :android => [:just_other_lane],
    #       :no_platform => [:a_not_platform_lane]
    #     }
    # @param [String] repo_url
    def self.peek_fastfile_configuration(repo_url: nil, provider_credential: nil)
    end

    def client
      @_client
    end

    def session_valid?
      client.login.to_s.length > 0
    rescue StandardError
      false
    end

    def username
      client.login
    end

    # Returns the urls of the pull requests for a given branch and state.
    # If branches is not provided, all target branches are considered.
    # @param [String] repo_url
    # @param [Array[String] || nil] branches, Either an array of target branches names or nil.
    # @param [String] state, Either open, closed, or all to filter by state. Default: open.
    # @return [String] HTML URL for the given pull request query.
    def pull_requests(repo_url: nil, branches: nil, state: "open")
      all_open_pull_requests = client.pull_requests(repo_from_url(repo_url), state: state)

      # if no specific branch, return all open prs
      return all_open_pull_requests.map(&:html_url) if branches&.count == 0

      pull_requests_on_branch = all_open_pull_requests.select { |pull_request| branches.include?(pull_request.base.ref) }
      # we want only the PRs whose latest commit was to one of the branches passed in
      logger.debug("Returning all open prs from: #{repo_full_name}, branches: #{branches}, pr count: #{pull_requests_on_branch.count}")
      return pull_requests_on_branch.map(&:html_url)
    end

    # Retrieve all commits' sha from a given repo_url and branch.
    # @param [String] repo_url
    # @param [String] branch
    # @return [Array[String]] List of SHA for a given branch and repo.
    def all_commits_sha_for_branch(repo_url: nil, branch: nil)
      return client.commits(repo_from_url(repo_url), branch).map(&:sha)
    end

    # Retrieve the list of sha for a given pull request number.
    # @param [String] repo_url
    # @param [Integer] number, of the pull request.
    # @return [Array[String]] Array of SHA for the given pull request.
    def commits_sha_from_pull_request(repo_url: nil, number: nil)
      client.pull_commits(repo_from_url(repo_url), number).map(&:sha)
    end

    # Returns the last sha for every pull request that targets a list of branches (or all if not given) and status (or open if not given)
    # @param [String] repo_url
    # @param [Array[String] || nil] branches, Either an array of target branches names or nil.
    # @param [String] state, Either open, closed, or all to filter by state. Default: open.
    # @return [Array[String]] Array of the last commit SHA for the given repo and state.
    def last_commit_sha_for_pull_requests(repo_url: nil, branches: nil, state: "open")
      pull_requests_urls = self.pull_requests(repo_url: repo_from_url(repo_url), branches: branches, state: state)
      numbers = pull_requests_urls.map { |url| URI.parse(url) }.map(&:path).collect { |path| path.split("/").last }
      return numbers.map { |number| commits_sha_from_pull_request(repo_url: repo_from_url(repo_url), number: number) }.map(&:last)
    end

    # returns the statused of a given commit sha for a given repo specifically for fastlane.ci
    # TODO: add support for filtering status types, to allow listing of just fastlane.ci status reports
    #       This has to wait for now, until we decide how we separate them for each project, as multiple projects
    #       can run builds for one repo
    def statuses_for_commit_sha(repo_full_name: nil, sha: nil)
      all_statuses = client.statuses(repo_full_name, sha)
      only_ci_statuses = all_statuses.select { |status| status.context.start_with?(GitHubService.status_context_prefix) }
      return only_ci_statuses
    end

    # updates the most current commit to "pending" on all open prs if they don't have a status.
    # returns a list of commits that have been updated to `pending` status
    def update_all_open_prs_without_status_to_pending_status!(repo_full_name: nil, status_context: nil)
      open_pr_commits = self.last_commit_sha_for_all_open_pull_requests(repo_full_name: repo_full_name)
      updated_commits = []
      open_pr_commits.each do |sha|
        statuses = self.statuses_for_commit_sha(repo_full_name: repo_full_name, sha: sha)
        if statuses.count == 0
          self.set_build_status!(repo: repo_full_name, sha: sha, state: "pending", status_context: status_context)
          updated_commits << sha
        end
      end
      return updated_commits
    end

    # @return [Array[GitRepoConfig]]
    def repos
      client.repos({}, query: { sort: "asc" }).map(&GitRepoConfig.from_octokit_repo!)
    end

    # @return [Array[String]]
    def branches(repo_url: nil)
      client.branches(repo_from_url(repo_url)).map(&:name)
    end

    # Does the client with the associated credentials have access to the specified repo?
    # @repo [String] Repo URL as string
    def access_to_repo?(repo_url: nil)
      client.repository?(repo_from_url(repo_url))
    end

    # The `target_url`, `description` and `context` parameters are optional
    # @repo [String] Repo URL as string
    def set_build_status!(repo: nil, sha: nil, state: nil, target_url: nil, description: nil, status_context:)
      status_context = GitHubService.status_context_prefix + status_context
      state = state.to_s

      # Available states https://developer.github.com/v3/repos/statuses/
      if state == "missing_fastfile" || state == "ci_problem"
        state = "failure"
      end

      available_states = ["error", "failure", "pending", "success", "ci_problem"]
      raise "Invalid state '#{state}'" unless available_states.include?(state)

      # We auto receive the SLUG, so that the user of this class can pass a full URL also
      repo = repo.split("/")[-2..-1].join("/")

      if description.nil?
        description = "All green" if state == "success"
        description = "Still running" if state == "pending"

        # TODO: what's the difference?
        description = "Build encountered a failure" if state == "failure"
        description = "Build encountered an error " if state == "error"
      end

      # this needs to be synchronous because we're doing it during initialization of our build runner
      state_details = target_url.nil? ? "#{repo}, sha #{sha}" : target_url
      logger.debug("Setting status #{state} -> #{status_context} on #{state_details}")
      client.create_status(repo, sha, state, {
        target_url: target_url,
        description: description,
        context: status_context
      })
    rescue StandardError => ex
      logger.error(ex)
      # TODO: how do we handle GitHub errors
      # In this case `create_status` will cause an exception
      # if the user doesn't have write permission for the repo
      raise ex
    end

    protected

    def repo_from_url(repo_url)
      return repo_url.sub("https://github.com/", "")
    end
  end
end
