require_relative "../../shared/authenticated_controller_base"
require_relative "./build_websocket_backend"
require "pathname"

module FastlaneCI
  # Controller for a single project view. Responsible for updates, triggering builds, and displaying project info
  class BuildController < AuthenticatedControllerBase
    HOME = "/projects/*/builds"

    use(FastlaneCI::BuildWebsocketBackend)

    get "#{HOME}/*" do |project_id, build_number|
      build_number = build_number.to_i

      project = self.user_project_with_id(project_id: project_id)
      build = project.builds.find { |b| b.number == build_number }

      # Fetch all the active runners, and see if there is one WIP
      current_build_runner = Services.build_runner_service.find_build_runner(
        project_id: project_id,
        build_number: build_number
      )

      raise "Couldn't find build runner for project #{project_id} with build_number #{build_number}" if current_build_runner.nil?

      locals = {
        project: project,
        build: build,
        title: "Project #{project.project_name}, Build #{build.number}",
        existing_rows: current_build_runner.all_build_output_log_rows.map(&:html)
      }
      erb(:build, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
