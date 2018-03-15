require_relative "../../shared/authenticated_controller_base"
require_relative "../../shared/models/job_trigger"
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

      branch_to_build = project.job_triggers.select { |trigger| trigger.type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual] }.first.branch
      service.shallow_clone(branch: branch_to_build)
      current_sha = service.all_commits_sha_for_branch.last

      build_runner = FastlaneBuildRunner.new(
        sha: current_sha,
        github_service: service,
        work_queue: FastlaneCI::GitRepo.git_action_queue # using the git repo queue because of https://github.com/ruby-git/ruby-git/issues/355
      )
      build_runner.setup(parameters: nil)
      Services.build_runner_service.add_build_runner(build_runner: build_runner)

      redirect("#{HOME}/#{project_id}/builds/#{build_runner.current_build_number}")
    end

    post "#{HOME}/:project_id/save" do
      project_id = params[:project_id]
      project = self.user_project_with_id(project_id: project_id)
      project.lane = params["selected_lane"]
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

      fastfile_config = FastlaneCI::GitHubService.peek_fastfile_configuration(
        repo_url: "#{org}/#{repo_name}",
        branch: branch,
        provider_credential: provider_credential
      )

      fastfile_config.to_json
    end

    post "#{HOME}/add/*/*" do |org, repo_name|
      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      repo_config = FastlaneCI::GitHubService.repos(provider_credential: provider_credential).select { |repo| repo.full_name == org + "/" + repo_name }.first

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
        github_service.shallow_clone(branch: branch)
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

      relative_fastfile_path = nil
      available_lanes = []
      absolute_fastfile_path = project.local_fastfile_path
      unless absolute_fastfile_path.nil?
        parser = Fastlane::FastfileParser.new(path: absolute_fastfile_path)
        available_lanes = parser.available_lanes

        project_path = project.repo_config.local_repo_path
        relative_fastfile_path = Pathname.new(absolute_fastfile_path).relative_path_from(Pathname.new(project_path))
      end

      locals = {
        project: project,
        title: "Project #{project.project_name}",
        available_lanes: available_lanes,
        fastfile_path: relative_fastfile_path # TODO: rename param `fastfile_path` to `relative_fastfile_path`
      }

      erb(:project, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
