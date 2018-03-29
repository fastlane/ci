require_relative "github_worker_base"
require_relative "worker_scheduler"
require_relative "../services/build_service"
require_relative "../shared/models/job_trigger"
require_relative "../shared/logging_module"

require "time"

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
      build_service = FastlaneCI::Services.build_service

      # Sorted by newest timestamps first
      sorted_builds = build_service.list_builds(project: self.project).sort { |x, y| y.timestamp.to_i <=> x.timestamp.to_i }

      # All the shas for builds we have run, sorted by build timestamp (newest builds first)
      local_build_shas_by_date = sorted_builds.map(&:sha)

      # Look at the last commit time, then subtract 5 minutes from it to account for clock drift between this computer and the git repo
      drift_time_seconds = 300
      since_time_utc_seconds = sorted_builds.first&.timestamp.to_i - drift_time_seconds || Time.now.utc.to_i - drift_time_seconds

      since_time_utc = Time.at(since_time_utc_seconds.to_i).utc
      repo_full_name = self.project.repo_config.full_name
      logger.debug("Looking for commits that are newer than #{since_time_utc.iso8601} for #{self.project.project_name} (#{repo_full_name})")

      # Get all the new commits since the last build time (minus whatever drift we determined above)
      new_commits = github_service.get_commits(repo_full_name: repo_full_name, since_time_utc: since_time_utc)
      logger.debug("Found #{new_commits.length} potential new commit(s)") unless new_commits.length == 0
      new_commit_shas = new_commits.map(&:sha)

      # Trim out all the commits that we already have a build for, so we're just left with the new commits
      shas_to_build = new_commit_shas - local_build_shas_by_date
      if shas_to_build.length == 0
        logger.debug("No new commits found")
        return
      end

      logger.debug("Creating a build task for commits: #{shas_to_build}")

      shas_to_build.each do |sha|
        self.create_and_queue_build_task(sha: sha)
      end
    end

    def work
      check_for_new_commits
    end
  end
end
