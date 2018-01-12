require_relative "../../shared/controller_base"

module FastlaneCI
  class ProjectController < ControllerBase
    HOME = "/projects"

    get "#{HOME}/*" do |project_id|
      project = Services::CONFIG_SERVICE.projects.find { |a| a.id == project_id }
      locals = {
        project: project,
        title: "Project #{project.project_name}"
      }
      erb(:project, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
