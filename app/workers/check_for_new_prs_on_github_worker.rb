require_relative "github_worker_base"
require_relative "worker_scheduler"
require_relative "../services/build_service"
require_relative "../shared/models/job_trigger"
require_relative "../shared/logging_module"

require "time"
require "set"

module FastlaneCI
  # Responsible for checking if there are new pull requests via polling.
  class CheckForNewPullRequestsOnGithubWorker < GitHubWorkerBase
    include FastlaneCI::Logging

    # @return [JobTrigger::TRIGGER_TYPE]
    attr_reader :trigger_type

    # Class responsible for scheduling fastlane.ci workers.
    #
    # @return [WorkerScheduler]
    attr_reader :scheduler

    # @return [GitHubService]
    attr_reader :github_service

    # Instantiates a new `CheckForNewPullRequestsOnGithubWorker` object.
    #
    # @param [ProviderCredential] provider_credential: The credential needed to communicate with GitHub API.
    # @param [Project] project: The project you wish to check new `Build`s on.
    # @param [NotificationService] notification_service: A notification service to inject into new builds to enqueue.
    def initialize(provider_credential:, project:, notification_service:)
      @trigger_type = FastlaneCI::JobTrigger::TRIGGER_TYPE[:pull_request]
      @scheduler = WorkerScheduler.new(interval_time: 10)
      @github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)

      # This starts the work by calling `work`
      super(
        provider_credential: provider_credential,
        project: project,
        notification_service: notification_service
      )
    end

    # Checks for new commits on open pull requests that correspond to job triggers.
    def work
      self.busy = true
      check_for_new_pull_requests
      self.busy = false
    end

    private

    # The name of the repository to get the open pull requests from.
    #
    # @return [String]
    attr_reader :repo_full_name

    # An array of the previous builds executed.
    #
    # @return [Array[Build]]
    attr_reader :builds

    # Checks for new commits on pull requests associated with user-defined job triggers.
    #
    # 1. Sets up the data needed by the worker
    # 2. Filters the pull requests open by if the current commit sha exists in a previously run `Build`.
    # 3. Checks if no pull request new commits have been found, and returns early if that's the case.
    # 4. Enqueues new `Build`s for the commits that haven't been previously been enqueued in a `Build`.
    def check_for_new_pull_requests
      setup_worker_data
      pull_requests_with_new_commits = filter_pull_requests_with_commit_shas_in_builds

      if pull_requests_with_new_commits.empty?
        logger.debug("No new commits found for #{project.project_name} (#{repo_full_name})")
        return
      end

      pr_details = pull_requests_with_new_commits.map { |pr| "#{pr.repo_full_name}:#{pr.branch}:#{pr.current_sha}" }
      logger.debug("Creating build task(s) for #{project.project_name} (#{repo_full_name}): #{pr_details}")

      enqueue_new_builds(pull_requests_with_new_commits)
    end

    # Sets up the data needed by the worker.
    def setup_worker_data
      @repo_full_name = project.repo_config.full_name
      logger.debug("Checking for new commits: #{project.project_name} (#{repo_full_name})")

      # Sorted by newest timestamps first.
      @builds = FastlaneCI::Services.build_service.list_builds(project: project)
    end

    # Filters out all pull requests with the current commit sha in the list of builds previously run.
    #
    # @return [Array[Octokit::Client::PullRequest]]
    def filter_pull_requests_with_commit_shas_in_builds
      # All the shas for builds we have run and dump it to a set so we can filter with it.
      local_build_shas_set = builds.map(&:sha).to_set

      # Get all open pull requests for the repository.
      open_pull_requests = github_service.open_pull_requests(repo_full_name: repo_full_name)

      # Filter out the pull requests with commit shas that are already in the builds.
      return open_pull_requests.reject { |pr| local_build_shas_set.include?(pr.current_sha) }
    end

    # Enqueues new `Build`s for commits on pull requests that haven't been previously been enqueued in a `Build`.
    #
    # @param [Array[Octokit::Client::PullRequest]] pull_requests
    def enqueue_new_builds(pull_requests)
      pull_requests.each do |pr|
        git_fork_config = GitForkConfig.new(
          sha: pr.current_sha,
          branch: pr.branch,
          clone_url: pr.clone_url,
          ref: pr.git_ref
        )
        create_and_queue_build_task(
          trigger: project.find_triggers_of_type(trigger_type: :pull_request).first,
          git_fork_config: git_fork_config
        )
      end
    end
  end
end
