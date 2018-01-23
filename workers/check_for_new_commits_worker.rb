require_relative "worker_base"

module FastlaneCI
  # Responsible for checking if there have been new commits
  # We have to poll, as there is no easy way to hear about
  # new commits from web events, as the CI system might be behind
  # firewalls
  class CheckForNewCommitsWorker < WorkerBase
    attr_accessor :user
    attr_accessor :user_config_service
    attr_accessor :provider

    def initialize(user: nil, provider: nil, project: nil)
      self.user = user
      self.provider = provider
      self.project = project
      self.user_config_service = FastlaneCI::ConfigService.new(ci_user: user)
      super()
    end

    def work
      repo = self.project.repo
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
        FastlaneCI::GitHubSource.source_from_provider(provider: self.provider).set_build_status!(
          repo: project.repo_url,
          sha: current_sha,
          state: :success,
          target_url: nil
        )
      end
    end

    def timeout
      3
    end
  end
end
