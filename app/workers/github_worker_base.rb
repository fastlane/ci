require_relative "worker_base"
require_relative "../shared/models/provider_credential"
require_relative "../shared/logging_module"
require_relative "../services/build_runner_service"
require_relative "../services/code_hosting/git_hub_service"

module FastlaneCI
  # Base class for GitHub workers
  class GitHubWorkerBase < WorkerBase
    include FastlaneCI::Logging

    attr_reader :provider_credential
    attr_reader :project
    attr_reader :github_service
    attr_reader :target_branches_set
    attr_reader :project_full_name
    attr_reader :serial_task_queue
    attr_reader :notification_service

    def provider_type
      return FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
    end

    def initialize(provider_credential:, project:, notification_service:)
      @provider_credential = provider_credential
      @github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)
      @project = project
      @notification_service = notification_service
      @target_branches_set = Set.new

      project.job_triggers.each do |trigger|
        if trigger.type == trigger_type
          target_branches_set.add(trigger.branch)
        end
      end

      @project_full_name =
        if project.repo_config.kind_of?(FastlaneCI::GitHubRepoConfig) &&
           !project.repo_config.full_name.nil?
          project.repo_config.full_name
        else
          project.repo_config.git_url
        end

      @serial_task_queue = TaskQueue::TaskQueue.new(name: "#{project_full_name}:#{provider_credential.ci_user.email}")

      super() # This starts the work by calling `work`
    end

    def thread_id
      if @thread_id
        return @thread_id
      end

      time_nano = Time.now.nsec
      current_class_name = self.class.name.split("::").last
      @thread_id = "#{current_class_name}:#{time_nano}: #{serial_task_queue.name}"
      return @thread_id
    end

    def create_and_queue_build_task(trigger:, git_fork_config:)
      credential = provider_credential
      current_project = project
      current_sha = git_fork_config.sha

      unless Services.build_runner_service.find_build_runner(project_id: current_project.id, sha: current_sha).nil?
        return
      end

      build_runner = RemoteRunner.new(
        project: current_project,
        github_service: github_service,
        git_fork_config: git_fork_config,
        trigger: trigger
      )
      build_task = Services.build_runner_service.add_build_runner(build_runner: build_runner)

      logger.debug("Adding task for #{project_full_name}: #{credential.ci_user.email}: #{current_sha[-6..-1]}")
      return build_task
    end

    def trigger_type
      not_implemented(__method__)
    end

    def work
      not_implemented(__method__)
    end
  end
end
