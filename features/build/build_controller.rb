require_relative "../../shared/authenticated_controller_base"
require_relative "./build_websocket_backend"
require "pathname"

module FastlaneCI
  # Controller for a single project view. Responsible for updates, triggering builds, and displaying project info
  class BuildController < AuthenticatedControllerBase
    HOME = "/projects/*/builds"

    use(FastlaneCI::BuildWebsocketBackend)

    get "#{HOME}/*" do |project_id, build_id|
      project = self.user_project_with_id(project_id: project_id)
      build = project.builds.find { |b| b.sha == build_id } # TODO: We need a build ID, sha isn't enough

      current_runner_service = TestRunnerService.test_runner_services.find do |t| 
        t.project.id == project_id && t.sha == build_id # TODO: just as above, use actual identification
      end

      locals = {
        project: project,
        build: build,
        title: "Project #{project.project_name}, Build #{build.sha}",
        existing_rows: current_runner_service.all_lines.collect { |a| a[:html] }
      }
      erb(:build, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
