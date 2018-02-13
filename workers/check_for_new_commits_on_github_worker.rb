require_relative "worker_base"
require_relative "../services/build_service"
require_relative "../shared/models/provider_credential"
require_relative "../shared/logging_module"
require_relative "../services/test_runner_service"

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

    attr_writer :git_repo

    def provider_type
      return FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
    end

    def initialize(provider_credential: nil, project: nil)
      self.provider_credential = provider_credential
      self.project = project
      super()
      time_nano = Time.now.nsec
      project_full_name = project.repo_config.git_url

      if project.repo_config.kind_of?(FastlaneCI::GitRepoConfig)
        project_full_name = project.repo_config.full_name unless project.repo_config.full_name.nil?
      end

      self.thread_id = "GithubWorker:#{time_nano}: #{project_full_name}: #{provider_credential.ci_user.email}"
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

    def work
      if ENV["FASTLANE_CI_SUPER_VERBOSE"]
        logger.debug("Checking for new commits on GitHub")
      end
      repo = self.git_repo
      repo.fetch # is needed to see if there are new branches

      # TODO: ensure BuildService subclasses are thread-safe
      build_service = FastlaneCI::Services.build_service

      # TODO: don't reach into this object's attributes like this
      repo.git.branches.remote.each do |branch|
        next if branch.name.start_with?("HEAD ->") # not sure what this is for

        # Check out the specific branch
        # this will detach our current head
        # TODO: we probably have to add a lock system for repos
        # as we access repos here, and also in the test runners
        repo.git.reset_hard # as there might be un-committed changes in there
        branch.checkout
        current_sha = repo.most_recent_commit.sha

        builds = build_service.list_builds(project: self.project)
        if builds.map(&:sha).include?(current_sha)
          next
        end
        if ENV["FASTLANE_CI_SUPER_VERBOSE"]
          logger.debug("Detected new branch #{branch.name} with sha #{current_sha}")
        end
        credential = self.provider_credential
        current_project = self.project
        thread = Thread.new do
          FastlaneCI::TestRunnerService.new(
            project: current_project,
            sha: current_sha,
            provider_credential: credential
          ).run
        end

        project_full_name = current_project.repo_config.git_url
        if current_project.repo_config.kind_of?(FastlaneCI::GitRepoConfig)
          project_full_name = current_project.repo_config.full_name unless current_project.repo_config.full_name.nil?
        end

        thread[:thread_id] = "GithubWorkerChild: #{project_full_name}: #{credential.ci_user.email}: #{current_sha[-6..-1]}"
      end
    end

    def timeout
      5
    end
  end
end
