require_relative "github_worker_base"
require_relative "../shared/models/job_trigger"
require_relative "../shared/logging_module"

module FastlaneCI
  # Responsible for starting off builds nightly
  class NightlyBuildGithubWorker < GithubWorkerBase
    include FastlaneCI::Logging
    NIGHTLY_CRON_TIME = "0 0 * * *"

    attr_accessor :scheduler
    attr_accessor :trigger_type

    def initialize(provider_credential: nil, project: nil)
      self.trigger_type = FastlaneCI::JobTrigger::TRIGGER_TYPE[:nightly]
      self.scheduler = WorkerScheduler.new(cron_schedule: NIGHTLY_CRON_TIME)

      super # This starts the work by calling `work`
    end

    def work
      logger.debug("Running nightly builds on GitHub")

      self.target_branches do |git, branch|
        current_sha = repo.most_recent_commit.sha
        logger.debug("Running Nightly build on branch #{branch.name} with sha #{current_sha}")

        self.create_and_queue_build_task
      end
    end
  end
end
