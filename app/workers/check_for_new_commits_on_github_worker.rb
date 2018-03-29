require_relative "github_worker_base"
require_relative "worker_scheduler"
require_relative "../services/build_service"
require_relative "../shared/models/job_trigger"
require_relative "../shared/logging_module"

require "time"
require "set"

module FastlaneCI
  # Responsible for checking if there have been new commits
  # We have to poll, as there is no easy way to hear about
  # new commits from web events, as the CI system might be behind
  # firewalls
  class CheckForNewCommitsOnGithubWorker < GitHubWorkerBase
    include FastlaneCI::Logging

    attr_accessor :trigger_type
    attr_accessor :scheduler
    attr_reader :github_service

    def initialize(provider_credential: nil, project: nil)
      self.trigger_type = FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit]
      self.scheduler = WorkerScheduler.new(interval_time: 10)
      @github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)

      super(provider_credential: provider_credential, project: project) # This starts the work by calling `work`
    end

    def check_for_new_commits
      repo_full_name = self.project.repo_config.full_name
      logger.debug("Checking for new commits: #{self.project.project_name} (#{repo_full_name})")
      build_service = FastlaneCI::Services.build_service

      # Sorted by newest timestamps first
      builds = build_service.list_builds(project: self.project)

      # All the shas for builds we have run and dump it to a set so we can filter with it
      local_build_shas_set = builds.map(&:sha).to_set

      # Get all commits from the open PRs
      open_pull_requests = self.github_service.open_pull_requests(repo_full_name: repo_full_name)

      # Filter out the PR shas that are already in the builds
      new_commit_prs = open_pull_requests.reject { |pr| local_build_shas_set.include?(pr.current_sha) }

      if new_commit_prs.length == 0
        logger.debug("No new commits found for #{self.project.project_name} (#{repo_full_name})")
        return
      end

      pr_details = new_commit_prs.map { |pr| "#{pr.repo_full_name}:#{pr.branch}:#{pr.current_sha}" }
      logger.debug("Creating build task(s) for #{self.project.project_name} (#{repo_full_name}): #{pr_details}")

      new_commit_prs.each do |pr|
        git_fork_config = GitForkConfig.new(current_sha: pr.current_sha,
                                                 branch: pr.branch,
                                              clone_url: pr.clone_url)
        self.create_and_queue_build_task(sha: pr.current_sha, git_fork_config: git_fork_config)
      end
    end

    def work
      check_for_new_commits
    end
  end
end
