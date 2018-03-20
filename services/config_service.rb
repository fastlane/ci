require_relative "code_hosting/git_hub_service"
require_relative "config_data_sources/json_project_data_source"
require_relative "../shared/models/github_provider_credential"
require_relative "../shared/logging_module"

module FastlaneCI
  # Provides access to the fastlane.ci configuration, like which projects we're hosting
  class ConfigService
    include FastlaneCI::Logging

    attr_accessor :project_service
    attr_accessor :ci_user
    attr_accessor :active_code_hosting_services # dictionary of active_code_hosting_service_key to CodeHosting
    attr_accessor :clone_user_provider_credential

    def initialize(project_service: FastlaneCI::Services.project_service, ci_user: nil, clone_user_provider_credential:)
      self.clone_user_provider_credential = clone_user_provider_credential
      self.project_service = project_service
      self.ci_user = ci_user
      self.active_code_hosting_services = {}
    end

    # if the provider_credential is for user B, but the service was initialized using user A,
    # that means user A is doing things on behalf of user B
    def process_on_behalf?(provider_credential: nil)
      return provider_credential.ci_user != self.ci_user
    end

    def active_code_hosting_service_key(provider_credential: nil)
      return "#{provider_credential.provider_name}_#{self.ci_user.id}"
    end

    def restart_any_pending_work
      return unless Services.onboarding_service.correct_setup?

      # this helps during debugging
      # in the future we should allow this to be configurable behavior
      return if ENV["FASTLANE_CI_SKIP_RESTARTING_PENDING_WORK"]

      github_projects = projects(provider_credential: clone_user_provider_credential)
      github_service = FastlaneCI::GitHubService.new(provider_credential: clone_user_provider_credential)

      run_pending_github_builds(projects: github_projects, github_service: github_service)
      enqueue_builds_for_open_github_prs_with_no_status(projects: github_projects, github_service: github_service)
    end

    # In the event of a server crash, we want to run pending builds on server
    # initialization for all projects for the provider credentials
    def run_pending_github_builds(projects: nil, github_service: nil)
      logger.debug("Searching all projects for commits with pending status that need a new build")
      # For each project, rerun all builds with the status of "pending"
      projects.each do |project|
        pending_build_shas_needing_rebuilds = Services.build_service.pending_build_shas_needing_rebuilds(project: project)
        logger.debug("No pending work to reschedule for #{project.project_name}") if pending_build_shas_needing_rebuilds.count == 0

        # Enqueue each pending build rerun in an asynchronous task queue
        pending_build_shas_needing_rebuilds.each do |sha|
          logger.debug("Found sha #{sha} that needs a rebuild for #{project.project_name}")
          build_runner = FastlaneBuildRunner.new(
            project: project,
            sha: sha,
            github_service: github_service,
            work_queue: FastlaneCI::GitRepo.git_action_queue # using the git repo queue because of https://github.com/ruby-git/ruby-git/issues/355
          )
          build_runner.setup(parameters: nil)
          Services.build_runner_service.add_build_runner(build_runner: build_runner)
        end
      end
    end

    # We might be in a situation where we have an open pr, but no status yet
    # if that's the case, we should enqueue a build for it
    def enqueue_builds_for_open_github_prs_with_no_status(projects: nil, github_service: nil)
      logger.debug("Searching for open PRs with no status and starting a build for them")
      projects.each do |project|
        # TODO: generalize this sort of thing
        credential_type = project.repo_config.provider_credential_type_needed

        # we don't support anything other than GitHub right now
        next unless credential_type == FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]

        # Collect all the branches from the triggers on this project that are commit-based
        branches_to_check = project.job_triggers
                                   .select { |trigger| trigger.type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit] }
                                   .map(&:branch)
                                   .uniq

        repo_full_name = project.repo_config.full_name
        # let's get all commit shas that need a build (no status yet)
        commit_shas = github_service.last_commit_sha_for_all_open_pull_requests(repo_full_name: repo_full_name, branches: branches_to_check)

        # no commit shas need to be switched to `pending` state
        next unless commit_shas.count > 0

        commit_shas.each do |current_sha|
          logger.debug("Checking #{repo_full_name} sha: #{current_sha} for missing status")
          statuses = github_service.statuses_for_commit_sha(repo_full_name: repo_full_name, sha: current_sha)

          # if we have a status, skip it!
          next if statuses.count > 0

          logger.debug("Found sha: #{current_sha} in #{repo_full_name} missing status, adding build.")

          build_runner = FastlaneBuildRunner.new(
            project: project,
            sha: current_sha,
            github_service: github_service,
            work_queue: FastlaneCI::GitRepo.git_action_queue # using the git repo queue because of https://github.com/ruby-git/ruby-git/issues/355
          )
          build_runner.setup(parameters: nil)
          Services.build_runner_service.add_build_runner(build_runner: build_runner)
        end
      end
    end

    # Find the active code host for the provider_credential/user combination
    # or instantiate one if none are available
    def code_hosting_service(provider_credential: nil)
      code_hosting_service_key = active_code_hosting_service_key(provider_credential: provider_credential)
      code_hosting_service = self.active_code_hosting_services[code_hosting_service_key]
      return code_hosting_service unless code_hosting_service.nil?

      # TODO: not a big deal right now, but we should have a way of automatically generating the correct
      # CodeHostingService subclass based on the provider_credential type and maybe not have it right here.
      # A Java-style factory might be the right move here.
      case provider_credential.type
      when FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
        code_hosting_service = GitHubService.new(provider_credential: provider_credential)
        active_code_hosting_services[code_hosting_service_key] = code_hosting_service
      else
        raise "Unrecognized provider_credential #{provider_credential.type}"
      end

      return code_hosting_service
    end

    def octokit_projects(provider_credential: nil)
      # Get a list of all the repos `provider` has access to
      logger.debug("Getting code host for #{provider_credential.ci_user.email}, #{provider_credential.type}") if provider_credential.ci_user
      current_code_hosting_service = self.code_hosting_service(provider_credential: provider_credential)

      logger.debug("Finding projects we have access to with #{provider_credential.ci_user.email}, #{provider_credential.type}") if provider_credential.ci_user
      projects = self.project_service.projects.select do |project|
        current_code_hosting_service.access_to_repo?(repo_url: project.repo_config.git_url)
      end

      # return all projects that are the union of this current user's provider_credential, and the passed in provider_credential
      return projects
    end

    def project(id: nil, provider_credential: nil)
      current_ci_user_projects = self.projects(provider_credential: provider_credential)
      current_project = current_ci_user_projects.select { |project| project.id == id }.first
      return current_project
    end

    def projects(provider_credential: nil)
      if provider_credential.type == FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
        return self.octokit_projects(provider_credential: provider_credential)
      else
        raise "Unrecognized provider_credential #{provider_credential.type}"
      end
    end
  end
end
