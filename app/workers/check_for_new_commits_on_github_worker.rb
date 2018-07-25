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

    # @return [JobTrigger::TRIGGER_TYPE]
    attr_reader :trigger_type

    # Class responsible for scheduling fastlane.ci workers.
    #
    # @return [WorkerScheduler]
    attr_reader :scheduler

    # @return [GitHubService]
    attr_reader :github_service

    # Instantiates a new `CheckForNewCommitsOnGithubWorker` object.
    #
    # @param [ProviderCredential] provider_credential: The credential needed to communicate with GitHub API.
    # @param [Project] project: The project you wish to check new `Build`s on.
    # @param [NotificationService] notification_service: A notification service to inject into new builds to enqueue.
    def initialize(provider_credential:, project:, notification_service:)
      @trigger_type = FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit]
      @scheduler = WorkerScheduler.new(interval_time: 10)
      @github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)

      # This starts the work by calling `work`
      super(
        provider_credential: provider_credential,
        project: project,
        notification_service: notification_service
      )
    end

    # Checks for new commits on branches that correspond to job triggers.
    def work
      self.busy = true
      check_for_new_commits_on_branches
      self.busy = false
    end

    private

    # The name of the repository to get the commits from.
    #
    # @return [String]
    attr_reader :repo_full_name

    # An array of the previous builds executed.
    #
    # @return [Array[Build]]
    attr_reader :builds

    # The branch names associated with all the user defined commit triggers.
    #
    # @return [Set[String]]
    attr_reader :branches

    # Checks for new commits on branches associated with user-defined job triggers.
    #
    # 1. Sets up the data needed by the worker
    # 2. Filters the 'branch name' => 'commits' mapping based on whether the commit sha has already been run.
    # 3. Checks if no new commits have been found, and returns early if that's the case.
    # 4. Enqueues new `Build`s for the commits that haven't been previously been enqueued in a `Build`.
    def check_for_new_commits_on_branches
      setup_worker_data
      filtered_branch_name_to_commits = filter_branch_name_to_commits_mapping

      if filtered_branch_name_to_commits.empty?
        logger.debug(
          "No new commits found for #{project.project_name} on branches <#{branches.to_a.join(', ')}>"
        )
        return
      end
      logger.debug("Creating build task(s) for #{project.project_name} (#{repo_full_name})")

      enqueue_new_builds(filtered_branch_name_to_commits)
    end

    # Sets up the data needed by the worker.
    def setup_worker_data
      @repo_full_name = project.repo_config.full_name
      logger.debug("Checking for new commits: #{project.project_name} (#{repo_full_name})")

      # Get all the most recent builds sorted by newest timestamps.
      @builds = FastlaneCI::Services.build_service.list_builds(project: project)

      # Get the branch names associated with the user-defined commit triggers.
      @branches = project.find_triggers_of_type(trigger_type: :commit).map(&:branch).to_set
    end

    # Filter down the hash of `branch_name_to commits` by removing KVPs where the `commit.sha` has already been
    # run in an existing build.
    #
    # @return [Hash] { branch_name => [commit_0, commit_1, ..., commit_n], ... }
    def filter_branch_name_to_commits_mapping
      local_branch_name_to_builds = branch_name_to_builds

      return branch_name_to_commits.each_with_object({}) do |(branch_name, branch_commits), hash|
        # Filter out the mappings where the `branch_name` does not belong to the
        # commit trigger.
        next unless branches.include?(branch_name)

        builds = local_branch_name_to_builds[branch_name]

        # Reject the branch_commits that have already been enqueued in a build.
        hash[branch_name] = branch_commits.reject do |commit|
          build_shas = builds&.map(&:sha)&.to_set || Set.new
          build_shas.include?(commit.sha)
        end
      end
    end

    # Enqueues new `Build`s for commits that haven't been previously been enqueued in a `Build`.
    #
    # @param [Hash] branch_name_to_commits: { branch_name => [commit_0, commit_1, ..., commit_n], ... }
    def enqueue_new_builds(filtered_branch_name_to_commits)
      filtered_branch_name_to_commits.each do |branch_name, commits|
        commits.each do |commit|
          new_git_fork_config = GitForkConfig.new(
            sha: commit.sha,
            branch: branch_name,
            clone_url: project.repo_config.git_url
          )

          create_and_queue_build_task(
            trigger: project.find_triggers_of_type(trigger_type: :commit).first,
            git_fork_config: new_git_fork_config
          )
        end
      end
    end

    # Get a hash mapping of 'branch name' to an array of `Build`s which are associated with the given branch.
    # Filter the builds down by the branches that are part of commit triggers.
    #
    # @return [Hash] { "branch_name" => [Build_0, Build_1, ..., Build_n], ... }
    def branch_name_to_builds
      return builds.select { |build| branches.include?(build.branch) }
                   .each_with_object({}) { |build, hash| (hash[build.branch] ||= []).push(build) }
    end

    # Get a hash mapping of 'branch name' to an array of commits which are associated with the given branch.
    # Get all commits from the branches
    #
    # @return [Hash] { branch_name => [commit_0, commit_1, ..., commit_n], ... }
    def branch_name_to_commits
      return github_service.branch_name_to_recent_commits_for_branch(
        repo_full_name: repo_full_name, branches: branches
      )
    end
  end
end
