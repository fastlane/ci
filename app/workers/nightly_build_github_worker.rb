require_relative "github_worker_base"
require_relative "../shared/models/job_trigger"
require_relative "../shared/logging_module"

module FastlaneCI
  # Responsible for starting off builds nightly
  class NightlyBuildGithubWorker < GitHubWorkerBase
    include FastlaneCI::Logging
    NIGHTLY_CRON_TIME = "0 0 * * *"

    attr_reader :scheduler
    attr_reader :trigger_type

    def initialize(provider_credential:, project:, notification_service:)
      @trigger_type = FastlaneCI::JobTrigger::TRIGGER_TYPE[:nightly]
      @scheduler = WorkerScheduler.new(cron_schedule: NIGHTLY_CRON_TIME)
      @notification_service = notification_service

      # This starts the work by calling `work`
      super(
        provider_credential: provider_credential,
        project: project,
        notification_service: notification_service
      )
    end

    def do_build
      logger.debug("Running nightly build for #{project.project_name} (#{repo_full_name})")
      # TODO: build_service could be injected instead of referenced like this
      build_service = FastlaneCI::Services.build_service

      # Sorted by newest timestamps first
      sorted_builds = build_service.list_builds(project: project).sort { |x, y| y.timestamp.to_i <=> x.timestamp.to_i }

      # All the shas for builds we have run, sorted by build timestamp (newest builds first)
      local_build_shas_by_date = sorted_builds.map(&:sha)

      # Find all commits from the previous 24 hours and 10 minutes
      since_time_utc_seconds = Time.now.utc.to_i - (24 * 60 * 60 + 600)

      since_time_utc = Time.at(since_time_utc_seconds.to_i).utc
      repo_full_name = project.repo_config.full_name

      # rubocop:disable Metrics/LineLength
      logger.debug("Looking for commits that are newer than #{since_time_utc.iso8601} for #{project.project_name} (#{repo_full_name})")

      # Get all the new commits since the last build time (minus whatever drift we determined above)
      new_commits = github_service.recent_commits(repo_full_name: repo_full_name, since_time_utc: since_time_utc)
      unless new_commits.length == 0
        logger.debug("Found #{new_commits.length} commit(s) since the last run, building the most recent for #{project.project_name} (#{repo_full_name})")
      end
      # rubocop:enable Metrics/LineLength

      newest_commit = new_commits.map(&:sha).first

      if newest_commit.nil?
        # Ok, no new commits in the past day, then we can just rebuild the last build
        newest_commit = local_build_shas_by_date.first
        if newest_commit.nil?
          logger.debug("No commits found for nightly build in #{project.project_name} (#{repo_full_name})")
          return
        end
      end

      logger.debug(
        "Creating a build task for commit: #{newest_commit} from #{project.project_name} (#{repo_full_name})"
      )

      git_fork_config = GitForkConfig.new(
        sha: newest_commit,
        clone_url: project.repo_config.git_url
      )
      create_and_queue_build_task(
        git_fork_config: git_fork_config,
        trigger: project.find_triggers_of_type(trigger_type: :nightly).first
      )
    end

    def work
      self.busy = true
      do_build
      self.busy = false
    end
  end
end
