require_relative "api_controller"
require_relative "./view_models/build_view_model"

module FastlaneCI
  # Controller for providing all data relating to builds
  class BuildJSONController < APIController
    HOME = "/data/projects/:project_id/build"

    get "#{HOME}/:build_number" do |project_id, build_number|
      build = current_project.builds.find { |b| b.number == build_number.to_i }
      build_view_model = BuildViewModel.new(build: build)

      json(build_view_model)
    end

    def current_project
      current_project = FastlaneCI::Services.project_service.project_by_id(params[:project_id])
      halt(404) unless current_project

      return current_project
    end
  end
end
