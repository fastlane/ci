require_relative "../shared/authenticated_controller_base"
require_relative "./view_models/project_summary_view_model"
require_relative "./view_models/project_view_model"

module FastlaneCI
  # Controller for providing all data relating to projects
  class ProjectJSONController < AuthenticatedControllerBase
    HOME = "/data/projects"

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
  end
end
