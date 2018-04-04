require_relative "../shared/authenticated_controller_base"
require_relative "./view_models/build_view_model"
require_relative "./view_models/build_summary_view_model"

module FastlaneCI
  # Controller for providing all data relating to builds
  class BuildsJSONController < AuthenticatedControllerBase
    HOME = "/data/projects/:project_id/builds"

    get HOME do |project_id|
      # TODO: return NOT_FOUND if there is no project found
      project = user_project_with_id(project_id: project_id)
      builds_views_models = project.builds.map(&BuildSummaryViewModel.method(:viewmodel_from))

      return builds_views_models.to_json
    end

    get "#{HOME}/:build_number" do
      # TODO: return NOT_FOUND if there is no project found
      project_id = params[:project_id]
      build_number = params[:build_number].to_i
      project = user_project_with_id(project_id: project_id)
      # TODO: return NOT_FOUND if there is no build found
      build = project.builds.find { |b| b.number == build_number }
      return BuildViewModel.viewmodel_from(build).to_json
    end
  end
end
