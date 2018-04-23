require_relative "../shared/authenticated_controller_base"
require_relative "./view_models/project_summary_view_model"
require_relative "./view_models/project_view_model"

module FastlaneCI
  # Controller for providing all data relating to projects
  class ProjectJSONController < AuthenticatedControllerBase
    HOME = "/data/projects"

    # Get the payload from the body
    before do
      request.body.rewind
      body = request.body.read
      @request_payload = JSON.parse(body) unless body.empty?
    end

    get HOME do
      current_provider_credential = check_and_get_provider_credential
      current_user_config_service = self.current_user_config_service
      all_projects = current_user_config_service.projects(provider_credential: current_provider_credential)

      all_projects_view_models = all_projects.map do |project|
        ProjectSummaryViewModel.new(project: project, latest_build: project.builds.first)
      end

      return all_projects_view_models.to_json
    end

    get "#{HOME}/:project_id" do |project_id|
      project = user_project_with_id(project_id: params[:project_id])
      project_view_model = ProjectViewModel.new(project: project)

      return project_view_model.to_json
    end

    post HOME do
      required_params = Set["lane", "repo_org", "repo_name", "project_name", "trigger_type"]
      has_required_params = required_params.subset?(Set.new(@request_payload.keys))

      # TODO: throw bad request error
      raise "bad request" unless has_required_params

      provider_credential = check_and_get_provider_credential

      github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)

      selected_repo = github_service.repos.detect do |repo|
        @request_payload["repo_name"] == repo[:name] &&
          @request_payload["repo_org"] == repo[:owner][:login]
      end

      repo_config = GitHubRepoConfig.from_octokit_repo!(repo: selected_repo)

      platform, lane = @request_payload["lane"].split(" ") # Split "ios test_lane"
      project_name = @request_payload["project_name"]
      branch = @request_payload["branch"]
      trigger_type = @request_payload["trigger_type"]
      hour = @request_payload["hour"]
      minute = @request_payload["minute"]

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
        provider_credential: provider_credential,
        local_folder: project.local_repo_path,
        async_start: false,
        notification_service: FastlaneCI::Services.notification_service
      )

      repo.checkout_branch(branch: branch)
    end
  end
end
