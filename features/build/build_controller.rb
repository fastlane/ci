require_relative "../../shared/authenticated_controller_base"
require "pathname"

module FastlaneCI
  # Controller for a single project view. Responsible for updates, triggering builds, and displaying project info
  class BuildController < AuthenticatedControllerBase
    HOME = "/projects/*/builds"

    # get "/projects*/builds/*/stream" do |project_id, build_id|
    #   stream do |out|
    #     out << "It's gonna be legen -\n"
    #     sleep 2
    #     out << "- dary!\n"
    #   end
    # end

    get "/projects/*/builds/*" do |project_id, build_id|
      project = self.user_project_with_id(project_id: project_id)
      build = project.builds.find { |b| b.sha == build_id } # TODO: We need a build ID, sha isn't enough

      locals = {
        project: project,
        build: build,
        build_output: build.full_log,
        title: "Project #{project.project_name}, Build #{build.sha}"
      }
      erb(:build, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
