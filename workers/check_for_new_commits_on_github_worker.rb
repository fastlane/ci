require_relative "worker_base"
require_relative "../services/build_service"
require_relative "../shared/models/provider_credential"
require_relative "../shared/logging_module"
require_relative "../services/test_runner_service"
require_relative "../services/code_hosting/git_hub_service"

module FastlaneCI
  # Responsible for checking if there have been new commits
  # We have to poll, as there is no easy way to hear about
  # new commits from web events, as the CI system might be behind
  # firewalls
  class CheckForNewCommitsOnGithubWorker < WorkerBase
    include FastlaneCI::Logging

    attr_accessor :provider_credential
    attr_accessor :project

    attr_accessor :user_config_service
    attr_accessor :github_service

    attr_accessor :serial_task_queue
    attr_accessor :current_tasks

    attr_writer :git_repo

    def provider_type
      return FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
    end

    def initialize(provider_credential: nil, project: nil)
      self.provider_credential = provider_credential
      self.github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)
      self.project = project

      project_full_name = project.repo_config.git_url

      if project.repo_config.kind_of?(FastlaneCI::GitRepoConfig)
        project_full_name = project.repo_config.full_name unless project.repo_config.full_name.nil?
      end

      self.serial_task_queue = TaskQueue::TaskQueue.new(name: "#{project_full_name}:#{provider_credential.ci_user.email}")
      self.current_tasks = []

      super() # This starts the work by calling `work`
    end

    def thread_id
      if @thread_id
        return @thread_id
      end

      time_nano = Time.now.nsec
      @thread_id = "GithubWorker:#{time_nano}: #{self.serial_task_queue.name}"
      return @thread_id
    end

    # This is a separate method, so it's lazy loaded
    # since it will be run on the "main" thread if it were
    # part of the #initialize method
    def git_repo
      @git_repo ||= GitRepo.new(
        git_config: project.repo_config,
        provider_credential: provider_credential
      )
    end

    def wait_for_previous_tasks?
      # see how many tasks have not completed
      not_finished_tasks = self.current_tasks.reject(&:completed)

      # if we have any tasks that are not complete, return true so that we don't enque more
      return not_finished_tasks.length > 0
    end

    def work
      if ENV["FASTLANE_CI_SUPER_VERBOSE"]
        logger.debug("Checking for new commits on GitHub")
      end

      logger.debug("Checking if we should wait for any previous previous tasks to complete")
      should_wait = self.wait_for_previous_tasks?
      if should_wait
        logger.debug("We still have test runner tasks to finish, not enqueuing any more")
        return
      end

      logger.debug("No old test runner tasks, enqueuing new runner tasks")
      repo = self.git_repo

      # is needed to see if there are new branches (called async)
      repo.fetch

      # TODO: ensure BuildService subclasses are thread-safe
      build_service = FastlaneCI::Services.build_service

      self.current_tasks = []
      repo.git_and_remote_branches_each do |git, branch|
        if ENV["FASTLANE_CI_SUPER_VERBOSE"]
          # Not sure why this matters
          logger.debug("FOUND WEIRD BRANCH") if branch.name.start_with?("HEAD ->")
        end

        next if branch.name.start_with?("HEAD ->") # not sure what this is for

        # There might be un-committed changes in there, so ignore
        git.reset_hard

        # Check out the specific branch, this will detach our current head
        branch.checkout

        current_sha = repo.most_recent_commit.sha

        builds = build_service.list_builds(project: self.project)
        if builds.map(&:sha).include?(current_sha)
          next
        end

        if ENV["FASTLANE_CI_SUPER_VERBOSE"]
          logger.debug("Detected branch #{branch.name} with sha #{current_sha}")
        end

        credential = self.provider_credential
        current_project = self.project

        # This never stops because with each commit, it creates a new commit and then we think it's new, LOL
        check_for_commit_task = TaskQueue::Task.new(work_block: proc {
          FastlaneCI::TestRunnerService.new(
            project: current_project,
            sha: current_sha,
            github_service: self.github_service
          ).run
        })

        # We need this so we can check later if we should skip creating new test runner tasks
        self.current_tasks << check_for_commit_task

        project_full_name = current_project.repo_config.git_url
        if current_project.repo_config.kind_of?(FastlaneCI::GitRepoConfig)
          project_full_name = current_project.repo_config.full_name unless current_project.repo_config.full_name.nil?
        end

        logger.debug("Adding task for #{project_full_name}: #{credential.ci_user.email}: #{current_sha[-6..-1]}")
        self.serial_task_queue.add_task_async(task: check_for_commit_task)
      end
    end

    def sleep_interval
      10
    end
  end
end
