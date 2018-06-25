require_relative "api_controller"
require_relative "./view_models/project_summary_view_model"
require_relative "./view_models/project_view_model"

module FastlaneCI
  # Controller for providing all data relating to projects
  class ProjectJSONController < APIController
    HOME = "/data/projects"

    get HOME do
      all_projects = current_user_config_service.projects(provider_credential: current_user_provider_credential)

      all_projects_view_models = all_projects.map do |project|
        ProjectSummaryViewModel.new(project: project, latest_build: project.builds.first)
      end

      json(all_projects_view_models)
    end

    get "#{HOME}/:project_id" do |project_id|
      json(ProjectViewModel.new(project: current_project))
    end

    post HOME do
      required_params = Set["lane", "repo_org", "repo_name", "project_name", "trigger_type"]
      has_required_params = required_params.subset?(Set.new(params.keys))

      # TODO: throw bad request error
      raise "bad request" unless has_required_params

      selected_repo = github_service.repos.detect do |repo|
        params["repo_name"] == repo[:full_name]
      end

      repo_config = GitHubRepoConfig.from_octokit_repo!(repo: selected_repo)

      platform, lane = params["lane"].split(" ") # Split "ios test_lane"
      project_name = params["project_name"]
      branch = params["branch"]
      trigger_type = params["trigger_type"]
      hour = params["hour"]
      minute = params["minute"]

      # TODO: Until we make a proper interface to attach JobTriggers to a Project, let's add a manual one for the
      # selected branch.
      # TODO: get default branch when there is no branch selected
      triggers_to_add = [FastlaneCI::ManualJobTrigger.new(branch: branch.nil? ? "master" : branch)]

      case trigger_type
      when FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit]
        triggers_to_add << FastlaneCI::CommitJobTrigger.new(branch: branch)
      when FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual]
        logger.debug("Manual trigger selected - this is enabled by default")
        # Nothing to do here, manual trigger is added by default
      when FastlaneCI::JobTrigger::TRIGGER_TYPE[:nightly]
        triggers_to_add << FastlaneCI::NightlyJobTrigger.new(branch: branch, hour: hour.to_i, minute: minute.to_i)
      else
        raise "Couldn't create a JobTrigger"
      end

      # We now have enough information to create the new project.
      # TODO: add job_triggers here
      # We shouldn't be blocking manual trigger builds
      # if we do not provide an interface to add them.
      project = Services.project_service.create_project!(
        name: project_name,
        repo_config: repo_config,
        enabled: true,
        platform: platform,
        lane: lane,
        job_triggers: triggers_to_add
      )

      raise "Project couldn't be created" if project.nil?

      # Do this so we trigger the clone of the repo.
      # TODO: Do this wherever it should be done, as we must redirect
      # to the project details only when this task is finished.
      repo = GitRepo.new(
        git_config: repo_config,
        provider_credential: current_user_provider_credential,
        local_folder: project.local_repo_path,
        async_start: false,
        notification_service: FastlaneCI::Services.notification_service
      )

      repo.checkout_branch(branch: branch)

      return ProjectSummaryViewModel.new(project: project, latest_build: project.builds.first).to_json
    end

    def github_service
      FastlaneCI::GitHubService.new(provider_credential: current_user_provider_credential)
    end

    def current_project
      current_project = FastlaneCI::Services.project_service.project_by_id(params[:project_id])

      unless current_project
        json_error!(
          error_message: "Can't find project with ID #{params[:project_id]}",
          error_key: "Project.Missing",
          error_code: 404
        )
      end

      return current_project
    end
  end
end
