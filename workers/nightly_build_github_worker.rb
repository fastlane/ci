require_relative "github_worker_base"
require_relative "../shared/models/job_trigger"
require_relative "../shared/logging_module"

module FastlaneCI
  # Responsible for starting off builds nightly
  class NightlyBuildGithubWorker < GitHubWorkerBase
    include FastlaneCI::Logging
    NIGHTLY_CRON_TIME = "0 0 * * *"

    attr_accessor :scheduler
    attr_accessor :trigger_type

    def initialize(provider_credential: nil, project: nil)
      self.trigger_type = FastlaneCI::JobTrigger::TRIGGER_TYPE[:nightly]
      self.scheduler = WorkerScheduler.new(cron_schedule: NIGHTLY_CRON_TIME)

      super(provider_credential: provider_credential, project: project) # This starts the work by calling `work`
    end

    def work
      logger.debug("Running nightly builds on GitHub")

      self.target_branches do |branch|
        current_sha = self.git_repo_service.all_commits_sha_for_branch(branch: branch).last
        logger.debug("Running Nightly build on branch #{branch} with sha #{current_sha}")

        self.create_and_queue_build_task(sha: current_sha)
      end
    end
  end
end
