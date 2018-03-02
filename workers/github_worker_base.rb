require_relative "worker_base"
require_relative "../shared/models/provider_credential"
require_relative "../shared/logging_module"
require_relative "../services/test_runner_service"
require_relative "../services/code_hosting/git_hub_service"

module FastlaneCI
  # Base class for GitHub workers
  class GithubWorkerBase < WorkerBase
    include FastlaneCI::Logging

    attr_accessor :provider_credential
    attr_accessor :project
    attr_accessor :github_service
    attr_accessor :serial_task_queue
    attr_accessor :project_full_name
    attr_accessor :target_branches_set
    attr_writer :git_repo

    def provider_type
      return FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
    end

    def initialize(provider_credential: nil, project: nil)
      self.provider_credential = provider_credential
      self.github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)
      self.project = project

      self.target_branches_set = Set.new
      project.job_triggers.each do |trigger|
        if trigger.type == self.trigger_type
          self.target_branches_set.add(trigger.branch)
        end
      end

      self.project_full_name = project.repo_config.git_url

      if project.repo_config.kind_of?(FastlaneCI::GitRepoConfig)
        self.project_full_name = project.repo_config.full_name unless project.repo_config.full_name.nil?
      end

      self.serial_task_queue = TaskQueue::TaskQueue.new(name: "#{self.project_full_name}:#{provider_credential.ci_user.email}")

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

    def target_branches(&block)
      repo = self.git_repo

      # is needed to see if there are new branches (called async)
      repo.fetch

      repo.git_and_remote_branches_each do |git, branch|
        # Only need to look at branches that have associated nightly build triggers
        next unless self.target_branches_set.include?(branch.name)

        # There might be un-committed changes in there, so ignore
        git.reset_hard

        # Check out the specific branch, this will detach our current head
        branch.checkout

        block.call(git, branch)
      end
    end

    def create_and_queue_build_task
      repo = self.git_repo

      credential = self.provider_credential
      current_project = self.project
      current_sha = repo.most_recent_commit.sha

      build_task = TaskQueue::Task.new(work_block: proc {
        FastlaneCI::TestRunnerService.new(
          project: current_project,
          sha: current_sha,
          github_service: self.github_service
        ).run
      })

      logger.debug("Adding task for #{self.project_full_name}: #{credential.ci_user.email}: #{current_sha[-6..-1]}")
      self.serial_task_queue.add_task_async(task: build_task)

      build_task
    end

    def trigger_type
      not_implemented(__method__)
    end
  end
end