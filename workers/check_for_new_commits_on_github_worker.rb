require_relative "worker_base"
require_relative "../shared/models/provider_credential"

module FastlaneCI
  # Responsible for checking if there have been new commits
  # We have to poll, as there is no easy way to hear about
  # new commits from web events, as the CI system might be behind
  # firewalls
  class CheckForNewCommitsOnGithubWorker < WorkerBase
    attr_accessor :provider_credential
    attr_accessor :project
    attr_accessor :user_config_service
    attr_accessor :git_repo

    def provider_type
      return FastlaneCI::ProviderCredential::PROVIDER_TYPES[:github]
    end

    def initialize(provider_credential: nil, project: nil)
      self.provider_credential = provider_credential
      self.project = project
      self.git_repo = GitRepo.new(git_config: project.repo_config)
      super()
    end

    def work
      repo = self.git_repo
      repo.git.fetch # is needed to see if there are new branches

      repo.git.branches.remote.each do |branch|
        next if branch.name.start_with?("HEAD ->") # not sure what this is for

        # TODO: remember which commits we ran tests for already

        # Check out the specific branch
        # this will detach our current head
        branch.checkout
        current_sha = repo.git.log.first.sha
        # TODO: run tests here
        # The code below has to be merged with what's currently in
        # project_controller
        FastlaneCI::GitHubSource.source_from_provider(
          provider_credential: self.provider_credential
        ).set_build_status!(
          repo: project.repo_config.git_url,
          sha: current_sha,
          state: :success,
          target_url: nil
        )
      end
    end

    def timeout
      10 # 10 seconds seems reasonable
    end
  end
end
