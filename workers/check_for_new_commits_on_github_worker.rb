require_relative "github_worker_base"
require_relative "worker_scheduler"
require_relative "../services/build_service"
require_relative "../shared/models/job_trigger"
require_relative "../shared/logging_module"

module FastlaneCI
  # Responsible for checking if there have been new commits
  # We have to poll, as there is no easy way to hear about
  # new commits from web events, as the CI system might be behind
  # firewalls
  class CheckForNewCommitsOnGithubWorker < GitHubWorkerBase
    include FastlaneCI::Logging

    attr_accessor :trigger_type
    attr_accessor :current_tasks
    attr_accessor :scheduler

    def initialize(provider_credential: nil, project: nil)
      self.trigger_type = FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit]
      self.scheduler = WorkerScheduler.new(interval_time: 10)

      self.current_tasks = []

      super(provider_credential: provider_credential, project: project) # This starts the work by calling `work`
    end

    def wait_for_previous_tasks?
      # see how many tasks have not completed
      not_finished_tasks = self.current_tasks.reject(&:completed)

      # if we have any tasks that are not complete, return true so that we don't enque more
      return not_finished_tasks.length > 0
    end

    def work
      logger.debug("Checking for new commits on GitHub")

      logger.info("Checking if we should wait for any previous previous tasks to complete")
      should_wait = self.wait_for_previous_tasks?
      if should_wait
        logger.info("We still have test runner tasks to finish, not enqueuing any more")
        return
      end

      logger.info("No old test runner tasks, enqueuing new runner tasks")
      repo = self.git_repo

      # TODO: ensure BuildService subclasses are thread-safe
      build_service = FastlaneCI::Services.build_service

      self.current_tasks = []
      self.target_branches do |git, branch|
        current_sha = repo.most_recent_commit.sha

        # Skips branches that have previously been built
        builds = build_service.list_builds(project: self.project)
        if builds.map(&:sha).include?(current_sha)
          next
        end

        logger.debug("Detected new commit on branch #{branch.name} with sha #{current_sha}")
        # This never stops because with each commit, it creates a new commit and then we think it's new, LOL
        check_for_commit_task = self.create_and_queue_build_task

        # We need this so we can check later if we should skip creating new test runner tasks
        self.current_tasks << check_for_commit_task
      end
    end
  end
end
