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

    attr_reader :trigger_type
    attr_reader :scheduler
    attr_reader :github_service

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

    def work
      check_for_new_pull_requests
    end

    private

    def check_for_new_pull_requests
      repo_full_name = project.repo_config.full_name
      logger.debug("Checking for new commits: #{project.project_name} (#{repo_full_name})")
      build_service = FastlaneCI::Services.build_service

      # Sorted by newest timestamps first.
      builds = build_service.list_builds(project: project)

      # All the shas for builds we have run and dump it to a set so we can filter with it.
      local_build_shas_set = builds.map(&:sha).to_set

      # Get all commits from the open PRs.
      open_pull_requests = github_service.open_pull_requests(repo_full_name: repo_full_name)

      # Filter out the PR shas that are already in the builds.
      new_commit_prs = open_pull_requests.reject { |pr| local_build_shas_set.include?(pr.current_sha) }

      if new_commit_prs.empty?
        logger.debug("No new commits found for #{project.project_name} (#{repo_full_name})")
        return
      end

      pr_details = new_commit_prs.map { |pr| "#{pr.repo_full_name}:#{pr.branch}:#{pr.current_sha}" }
      logger.debug("Creating build task(s) for #{project.project_name} (#{repo_full_name}): #{pr_details}")

      new_commit_prs.each do |pr|
        git_fork_config = GitForkConfig.new(
          sha: pr.current_sha,
          branch: pr.branch,
          clone_url: pr.clone_url,
          ref: pr.git_ref
        )
        create_and_queue_build_task(
          sha: pr.current_sha,
          trigger: project.find_triggers_of_type(trigger_type: :commit).first,
          git_fork_config: git_fork_config,
          notification_service: notification_service
        )
      end
    end
  end
end
