require_relative "./json_authenticated_controller_base"
require_relative "./view_models/build_view_model"

module FastlaneCI
  # Controller for providing all data relating to builds
  class BuildJSONController < JSONAuthenticatedControllerBase
    HOME = "/data/project/:project_id/build"

    get "#{HOME}/:build_number" do |project_id, build_number|
      project = user_project_with_id(project_id: project_id)
      build = project.builds.find { |b| b.number == build_number.to_i }
      build_view_model = BuildViewModel.new(build: build)

      return build_view_model.to_json
    end
  end
end
