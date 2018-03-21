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
    attr_accessor :scheduler

    def initialize(provider_credential: nil, project: nil)
      self.trigger_type = FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit]
      self.scheduler = WorkerScheduler.new(interval_time: 10)

      super(provider_credential: provider_credential, project: project) # This starts the work by calling `work`
    end

    def work
      logger.debug("Checking for new commits in #{self.project.project_name}")
      repo = self.git_repo

      # TODO: ensure BuildService subclasses are thread-safe
      build_service = FastlaneCI::Services.build_service

      self.target_branches do |git, branch|
        current_sha = repo.most_recent_commit.sha

        # Skips branches that have previously been built
        builds = build_service.list_builds(project: self.project)
        next if builds.map(&:sha).include?(current_sha)

        logger.debug("Detected new commit in #{self.project.project_name} on branch #{branch.name} with sha #{current_sha}")
        # Pull to make sure we have the current contents
        repo.pull(use_global_git_mutex: false) # We are already protected by self.target_branches which uses the mutex

        logger.debug("Checking out commit #{current_sha} from on branch #{branch.name} in #{self.project.project_name}")
        repo.checkout_commit(sha: current_sha, use_global_git_mutex: false) # We are already protected by self.target_branches which uses the mutex
        # This never stops because with each commit, it creates a new commit and then we think it's new, LOL
        # repo.

        # When we're done, clean up by resetting
        reset_block = proc {
          repo.reset_hard!(use_global_git_mutex: false)
        }

        self.create_and_queue_build_task(sha: current_sha, task_ensure_block: reset_block)
      end
    end
  end
end
