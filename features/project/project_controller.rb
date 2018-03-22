require_relative "../../shared/authenticated_controller_base"
require_relative "../../shared/models/job_trigger"
require_relative "../../services/code_hosting/code_hosting_service"
require "pathname"
require "json"

module FastlaneCI
  # Controller for a single project view. Responsible for updates, triggering builds, and displaying project info
  class ProjectController < AuthenticatedControllerBase
    HOME = "/projects_erb"

    # Note: The order IS important for Sinatra, so this has to be
    # above the other URL
    #
    # TODO: this should actually be a POST request
    get "#{HOME}/:project_id/trigger" do
      project_id = params[:project_id]
      project = self.user_project_with_id(project_id: project_id)
      provider_credential = self.check_and_get_provider_credential

      service = FastlaneCI::GitHubService.new(provider_credential: provider_credential, project: project)
      manual_triggers_allowed = project.job_triggers.any? { |trigger| trigger.type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual] }

      unless manual_triggers_allowed
        status(403) # Forbidden
        body("Cannot build. There is no manual build trigger, for this branch, associated with this project.")
        return
      end

      branch_to_build = project.job_triggers.detect { |trigger| trigger.type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual] }.branch
      current_sha = service.all_commits_sha_for_branch.last
      # TODO: This should be delegated to the `build_runner` to free up the thread.
      service.clone(branch: branch_to_build, sha: current_sha)

      build_runner = FastlaneBuildRunner.new(
        sha: current_sha,
        github_service: service,
        work_queue: FastlaneCI::CodeHostingService.git_action_queue # using the git repo queue because of https://github.com/ruby-git/ruby-git/issues/355
      )
      build_runner.setup(parameters: nil)
      Services.build_runner_service.add_build_runner(build_runner: build_runner)

      redirect("#{HOME}/#{project_id}/builds/#{build_runner.current_build_number}")
    end

    post "#{HOME}/:project_id/save" do
      project_id = params[:project_id]
      project = self.user_project_with_id(project_id: project_id)
      project.platform = params["selected_lane"]&.split(" ")&.first || "no_platform"
      project.lane = params["selected_lane"].split(" ").last
      project.project_name = params["project_name"]

      # TODO: what's the best way to store that project in the config?
      # Wait for Josh' input
      FastlaneCI::Services.project_service.update_project!(project: project)
      redirect("#{HOME}/#{project_id}")
    end

    get "#{HOME}/add" do
      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      locals = {
          title: "Add new project",
          repos: FastlaneCI::GitHubService.repos(provider_credential: provider_credential)
      }
      erb(:new_project, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/add/*" do |repo_name|
      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      locals = {
          title: "Add new project",
          repo: repo_name,
          branches: FastlaneCI::GitHubService.branch_names(provider_credential: provider_credential, repo_full_name: repo_name)
      }

      erb(:new_project_form, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/lanes/*/*/*" do |org, repo_name, branch|
      content_type :json

      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      _, fastfile_config = FastlaneCI::GitHubService.peek_fastfile_configuration(
        repo_url: "#{org}/#{repo_name}",
        branch: branch,
        provider_credential: provider_credential
      )

      fastfile_config.to_json
    end

    post "#{HOME}/add/*/*" do |org, repo_name|
      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      repo_config = FastlaneCI::GitHubService.repos(provider_credential: provider_credential).detect { |repo| repo.full_name == org + "/" + repo_name }

      lane = params["selected_lane"]
      project_name = params["project_name"]
      branch = params["branch"]

      # We now have enough information to create the new project.
      project = Services.project_service.create_project!(
        name: project_name,
        repo_config: repo_config,
        enabled: true,
        platform: lane.split(" ").first,
        lane: lane.split(" ").last,
        # TODO: Until we make a proper interface to attach JobTriggers to a Project, let's add a manual one for the selected branch.
        job_triggers: [FastlaneCI::ManualJobTrigger.new(branch: branch)]
      )

      if !project.nil?
        github_service = FastlaneCI::GitHubService.new(
          provider_credential: provider_credential,
          project: project
        )
        github_service.clone(branch: branch)
        redirect("#{HOME}/#{project.id}")
      else
        raise "Project couldn't be created"
      end
    end

    # Details of a project settings
    get "#{HOME}/:project_id" do
      project = self.user_project_with_id(project_id: params[:project_id])

      # TODO: We now access a file directly from the submodule
      # That's of course far from ideal, and not something we want to do long term
      # Long term, the best appraoch would probably to have the FastfileParser be
      # its own Ruby gem, or even part of the fastlane/fastlane main repo
      # For now, this is good enough, as we'll be moving so fast with this one
      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      fastfile, = FastlaneCI::GitHubService.peek_fastfile_configuration(
        repo_url: project.repo_config.full_name,
        branch: project.job_triggers&.first&.branch || "master",
        provider_credential: provider_credential
      )

      locals = {
        project: project,
        title: "Project #{project.project_name}",
        available_lanes: fastfile.available_lanes
      }

      erb(:project, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
