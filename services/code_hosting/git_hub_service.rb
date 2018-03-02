require_relative "code_hosting_service"
require_relative "../../taskqueue/task_queue"
require_relative "../../shared/logging_module"

require "octokit"

module FastlaneCI
  # Data source that interacts with GitHub
  class GitHubService < CodeHostingService
    include FastlaneCI::Logging

    class << self
      attr_accessor :status_context
    end

    GitHubService.status_context = "fastlane.ci"

    # The email is actually optional for API access
    # However we ask for the email on login, as we also plan on doing commits for the user
    # and this way we can make sure to configure things properly for git to use the email
    attr_accessor :provider_credential

    def initialize(provider_credential: nil)
      self.provider_credential = provider_credential

      @_client = Octokit::Client.new(access_token: provider_credential.api_token)
      Octokit.auto_paginate = true # TODO: just for now, we probably should do smart pagination in the future
      @task_queue = TaskQueue::TaskQueue.new(name: "#{provider_credential.type}-#{provider_credential.email}")
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
    def open_pull_requests(repo_full_name: nil)
      return client.pull_requests(repo_full_name, state: "open")
    end

    # returns only the most recent commit_sha for every open pr
    def last_commit_sha_for_all_open_pull_requests(repo_full_name: nil)
      return self.open_pull_requests(repo_full_name: repo_full_name).map { |pull_request| pull_request.head.sha }
    end

    # returns the status of a given commit sha for a given repo
    def status_for_commit_sha(repo_full_name: nil, sha: nil)
      return client.statuses(repo_full_name, sha, context: GitHubService.status_context)
    end

    # updates the most current commit to "pending" on all open prs if they don't have a status.
    # returns a list of commits that have been updated to `pending` status
    def update_all_open_prs_without_status_to_pending_status!(repo_full_name: nil)
      open_pr_commits = self.last_commit_sha_for_all_open_pull_requests(repo_full_name: repo_full_name)
      updated_commits = []
      open_pr_commits.each do |sha|
        statuses = self.status_for_commit_sha(repo_full_name: repo_full_name, sha: sha)
        if statuses.count == 0
          self.set_build_status!(repo: repo_full_name, sha: sha, state: "pending")
          updated_commits << sha
        end
      end
      return updated_commits
    end

    # TODO: parse those here or in service layer?
    def repos
      client.repos({}, query: { sort: "asc" })
    end

    # Does the client with the associated credentials have access to the specified repo?
    # @repo [String] Repo URL as string
    def access_to_repo?(repo_url: nil)
      client.repository?(repo_url.sub("https://github.com/", ""))
    end

    # The `target_url`, `description` and `context` parameters are optional
    # @repo [String] Repo URL as string
    def set_build_status!(repo: nil, sha: nil, state: nil, target_url: nil, description: nil, context: GitHubService.status_context)
      state = state.to_s

      # Available states https://developer.github.com/v3/repos/statuses/
      available_states = ["error", "failure", "pending", "success"]
      raise "Invalid state '#{state}'" unless available_states.include?(state)

      # We auto receive the SLUG, so that the user of this class can pass a full URL also
      repo = repo.split("/")[-2..-1].join("/")

      # TODO: this will use the user's session, so their face probably appears there
      # As Josh already predicted, we're gonna need a fastlane.ci account also
      # that we use for all non-user actions.
      # This includes scheduled things, commit status reporting and probably more in the future

      if description.nil?
        description = "All green" if state == "success"
        description = "Still running" if state == "pending"

        # TODO: what's the difference?
        description = "Something went wrong" if state == "failure"
        description = "Something went wrong" if state == "error"
      end

      # TODO: Enable once the GitHub token is fixed
      #
      # Full docs for `create_status` over here
      # https://octokit.github.io/octokit.rb/Octokit/Client/Statuses.html

      task = TaskQueue::Task.new(work_block: proc {
        state_details = target_url.nil? ? "#{repo}, sha #{sha}" : target_url
        logger.debug("Setting status #{state} on #{state_details}")
        client.create_status(repo, sha, state, {
          target_url: target_url,
          description: description,
          context: context || GitHubService.status_context
        })
      })

      @task_queue.add_task_async(task: task)
    rescue StandardError => ex
      # TODO: how do we handle GitHub errors
      # In this case `create_status` will cause an exception
      # if the user doesn't have write permission for the repo
      raise ex
    end
  end
end
