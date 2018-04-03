require_relative "../../shared/authenticated_controller_base"
require_relative "./build_websocket_backend"
require "pathname"

module FastlaneCI
  # Controller for a single project view. Responsible for updates, triggering builds, and displaying project info
  class BuildController < AuthenticatedControllerBase
    HOME = "/projects_erb/*/builds"

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

      if current_build_runner
        existing_rows = current_build_runner.all_build_output_log_rows.map(&:html).join("\n")
      else
        # `current_build_runner` is only defined if the build was just run a while back
        # if the server was restarted, we're gonna end here in this code block
        build_log_artifact = build.artifacts.find do |current_artifact|
          # We can improve the detection in the future, to actually mark an artifact as "default output"
          current_artifact.type == "log" && current_artifact.reference.end_with?("fastlane.log")
        end

        if build_log_artifact
          existing_rows = File.read(build_log_artifact.provider.retrieve!(artifact: build_log_artifact)).gsub("\n", "<br />")
        else
          raise "Couldn't load previous output for build #{build_number}"
        end
      end

      locals = {
        project: project,
        build: build,
        title: "Project #{project.project_name}, Build #{build.number}",
        existing_rows: existing_rows
      }
      erb(:build, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
