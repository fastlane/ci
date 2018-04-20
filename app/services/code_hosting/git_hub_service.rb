require_relative "../../shared/logging_module"
require_relative "../../shared/github_handler"
require_relative "code_hosting_service"
require_relative "github_open_pr"

require "set"
require "octokit"

module FastlaneCI
  # Data source that interacts with GitHub
  class GitHubService < CodeHostingService
    include FastlaneCI::Logging
    include FastlaneCI::GitHubHandler

    class << self
      attr_accessor :status_context_prefix
    end

    GitHubService.status_context_prefix = "fastlane.ci: "

    def remote_status_updates_disabled?
      disable_status_update = ENV["FASTLANE_CI_DISABLE_REMOTE_STATUS_UPDATE"]
      return false if disable_status_update.nil?

      disable_status_update = disable_status_update.to_s
      return false if disable_status_update == "false" || disable_status_update == "0"

      return true
    end

    # The email is actually optional for API access
    # However we ask for the email on login, as we also plan on doing commits for the user
    # and this way we can make sure to configure things properly for git to use the email
    attr_reader :provider_credential

    def initialize(provider_credential: nil)
      @provider_credential = provider_credential
      @_client = Octokit::Client.new(access_token: provider_credential.api_token)
      Octokit.auto_paginate = true # TODO: just for now, we probably should do smart pagination in the future
    end

    def self.token_scope_validation_error(token)
      required = "repo"
      scopes = []

      client = Octokit::Client.new(access_token: token)
      github_action(client) do
        scopes = client.scopes
      end

      if scopes.include?(required)
        return nil
      end

      return scopes, required
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

    # returns all open pull requests on given repo
    # branches should be nil if you want all branches to be considered
    def open_pull_requests(repo_full_name: nil, branches: nil)
      all_open_pull_requests = []
      github_action(client) do
        all_open_pull_requests = client.pull_requests(repo_full_name, state: "open").map do |pr|
          # This can happen, not sure why, seems to do with other people's forks, maybe they don't exist?
          next if pr.head.repo.nil?

          GitHubOpenPR.new(
            current_sha: pr.head.sha,
            branch: pr.head.ref,
            repo_full_name: pr.head.repo.full_name,
            number: pr.number,
            clone_url: pr.head.repo.clone_url
          )
        end
      end

      # if no specific branch, return all open prs
      return all_open_pull_requests if branches.nil? || branches.count == 0

      branch_set = branches.to_set
      all_open_pull_requests_on_branch = all_open_pull_requests.select do |pull_request|
        branch_set.include?(pull_request.branch)
      end

      # we want only the PRs whose latest commit was to one of the branches passed in
      pr_count = all_open_pull_requests.count
      logger.debug("Returning all open prs from: #{repo_full_name}, branches: #{branches}, pr count: #{pr_count}")

      return all_open_pull_requests_on_branch
    end

    # returns the statused of a given commit sha for a given repo specifically for fastlane.ci
    # TODO: add support for filtering status types, to allow listing of just fastlane.ci status reports
    #       This has to wait for now, until we decide how we separate them for each project, as multiple projects
    #       can run builds for one repo
    def statuses_for_commit_sha(repo_full_name: nil, sha: nil)
      all_statuses = []

      github_action(client) do
        all_statuses = client.statuses(repo_full_name, sha)
      end

      only_ci_statuses = all_statuses.select do |status|
        status.context.start_with?(GitHubService.status_context_prefix)
      end

      return only_ci_statuses
    end

    # updates the most current commit to "pending" on all open prs if they don't have a status.
    # returns a list of commits that have been updated to `pending` status
    def update_all_open_prs_without_status_to_pending_status!(repo_full_name: nil, status_context: nil)
      open_pr_commits = open_pull_requests(repo_full_name: repo_full_name)
      updated_commits = []

      open_pr_commits.each do |open_pull_request|
        sha = open_pull_request.current_sha
        repo_full_name = open_pull_request.repo_full_name
        statuses = statuses_for_commit_sha(
          repo_full_name: repo_full_name,
          sha: sha
        )
        next unless statuses.count == 0

        if remote_status_updates_disabled?
          logger.debug("Remote status updates are disabled, remote status not updated for #{repo_full_name}, #{sha}")
        else
          set_build_status!(
            repo: repo_full_name,
            sha: sha,
            state: "pending",
            status_context: status_context
          )
        end

        updated_commits << sha
      end

      return updated_commits
    end

    def recent_commits(repo_full_name:, branch:, since_time_utc:)
      github_action(client) do
        next client.commits_since(repo_full_name, since_time_utc, branch)
      end
    end

    # TODO: parse those here or in service layer?
    def repos
      github_action(client) do
        next client.repos({}, query: { sort: "asc" })
      end
    end

    # @return [Array<String>] names of the branches for the given repo
    def branch_names(repo:)
      github_action(client) do
        next client.branches(repo).map(&:name)
      end
    end

    # Does the client with the associated credentials have access to the specified repo?
    # @repo [String] Repo URL as string
    def access_to_repo?(repo_url: nil)
      github_action(client) do
        next client.repository?(repo_url.sub("https://github.com/", ""))
      end
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

      if remote_status_updates_disabled?
        logger.debug("Remote status updates are disabled, remote build status not updated.")
      else
        github_action(client) do
          client.create_status(repo, sha, state, {
            target_url: target_url,
            description: description,
            context: status_context
          })
        end
      end
    rescue StandardError => ex
      logger.error(ex)
      raise ex
    end
  end
end
