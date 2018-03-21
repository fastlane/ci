require_relative "worker_base"
require_relative "../shared/models/provider_credential"
require_relative "../shared/logging_module"
require_relative "../services/build_runner_service"
require_relative "../services/code_hosting/code_hosting_service"

module FastlaneCI
  # Base class for GitHub workers
  class GitHubWorkerBase < WorkerBase
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
      self.project = project
      self.github_service = self.git_repo_service

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
      current_class_name = self.class.name.split("::").last
      @thread_id = "#{current_class_name}:#{time_nano}: #{self.serial_task_queue.name}"
      return @thread_id
    end

    # This is a separate method, so it's lazy loaded
    # since it will be run on the "main" thread if it were
    # part of the #initialize method
    def git_repo_service
      @git_repo ||= begin
        case self.provider_credential.type
        when FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
          service = FastlaneCI::GitHubService.new(provider_credential: self.provider_credential, project: self.project)
          return service
        else
          return nil
        end
      end
    end

    def target_branches(&block)
      self.git_repo_service.branch_names do |branch|
        next unless self.target_branches_set.include?(branch)
        git = self.git_repo_service.clone(branch: branch)

        yield(git, branch)
      end
    end

    def create_and_queue_build_task(sha:)
      credential = self.provider_credential
      current_sha = sha
      build_runner = FastlaneBuildRunner.new(
        sha: current_sha,
        github_service: self.github_service,
        work_queue: FastlaneCI::CodeHostingService.git_action_queue # using the git repo queue because of https://github.com/ruby-git/ruby-git/issues/355
      )
      build_runner.setup(parameters: nil)
      build_task = Services.build_runner_service.add_build_runner(build_runner: build_runner)

      logger.debug("Adding task for #{self.project_full_name}: #{credential.ci_user.email}: #{current_sha[-6..-1]}")
      return build_task
    end

    def trigger_type
      not_implemented(__method__)
    end
  end
end
