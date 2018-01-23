require_relative "worker_base"
require_relative "../services/build_service"
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

      # TODO: Services::BUILD_SERVICE doesn't work as the file isn't included
      # TODO: ugh, I'm doing something wrong, I think?
      json_folder_path = FastlaneCI::FastlaneApp::CONFIG_DATA_SOURCE.git_repo.path
      build_service = FastlaneCI::BuildService.new(data_source: BuildDataSource.new(json_folder_path: json_folder_path))

      repo.git.branches.remote.each do |branch|
        next if branch.name.start_with?("HEAD ->") # not sure what this is for

        # Check out the specific branch
        # this will detach our current head
        branch.checkout
        current_sha = repo.git.log.first.sha

        builds = build_service.list_builds(project: self.project)
        if builds.map { |b| b.sha }.include?(current_sha)
          next
        end

        github_source = FastlaneCI::GitHubSource.source_from_provider(
          provider_credential: self.provider_credential
        )
        # Store the current build output + artifacts
        current_build = FastlaneCI::Build.new(
          project: self.project,
          number: builds.count + 1,
          status: :pending,
          timestamp: Time.now,
          duration: -1,
          sha: current_sha
        )
        build_service.add_build!(
          project: self.project, 
          build: current_build
        )

        # Let GitHub know we're already running the tests
        github_source.set_build_status!(
          repo: project.repo_config.git_url,
          sha: current_sha,
          state: :pending,
          target_url: nil
        )

        start_time = Time.now
        sleep 20
        # TODO: run tests here!
        # TODO: Replace project_controller code with code from here
        duration = Time.now - start_time

        current_build.duration = duration
        current_build.status = :success
        build_service.add_build!(
          project: self.project, 
          build: current_build
        )
        # Report the build status to GitHub
        github_source.set_build_status!(
          repo: project.repo_config.git_url,
          sha: current_sha,
          state: :success,
          target_url: nil
        )
      end
    end

    def timeout
      5
    end
  end
end
