require_relative "../../shared/controller_base"
require_relative "./build_websocket_backend"
require_relative "../../services/services"
require "pathname"
require "uri"

module FastlaneCI
  # Controller for a single project view. Responsible for updates, triggering builds, and displaying project info
  # THIS IS NOT PROTECTED BY AUTHORIZATION DO NOT MUTATE DATA IN THIS CONTROLLER
  class BuildController < ControllerBase
    HOME = "/projects_erb/*/builds"
    COLOR_MAPPING = {
      30 => :black,
      31 => :red,
      32 => "#5cf442",
      33 => :yellow,
      34 => :blue,
      35 => :magenta,
      36 => :cyan,
      37 => :white
    }

    def self.build_url(project_id:, build_number:)
      return HOME.gsub("*", project_id) + "/#{build_number}"
    end

    use(FastlaneCI::BuildWebsocketBackend)

    get "#{HOME}/*/artifact/*" do |project_id, build_number, artifact_id|
      build_number = build_number.to_i

      project = FastlaneCI::Services.project_service.project_by_id(project_id)
      build = project.builds.find { |b| b.number == build_number }

      artifact = build.artifacts.find { |find_artifact| find_artifact.id == artifact_id }

      if artifact.nil?
        status(404) # Not found
        body("Cannot find artifact")
        return
      end

      begin
        artifact_reference = artifact.provider.retrieve!(artifact: artifact)
        raise "Artifact not found" if artifact_reference.nil?
      rescue StandardError
        status(404) # Not found
        body("Cannot find artifact")
        return
      end

      uri = URI.parse(artifact_reference)

      if uri.scheme.nil?
        if File.exist?(artifact_reference)
          send_file(artifact_reference, filename: artifact_reference, type: "Application/octet-stream")
        else
          status(404) # Not found
          body("Cannot find artifact")
          return
        end
      else
        redirect(artifact_reference)
      end
    end

    # Since this controller is now not protected by authorization
    # we might want to consider protecting this by ensuring we can only call it with
    # the current project somehow?
    get "#{HOME}/*" do |project_id, build_number|
      build_number = build_number.to_i

      project = FastlaneCI::Services.project_service.project_by_id(project_id)
      raise "Project #{project_id} not found" if project.nil?

      build = project.builds.find { |b| b.number == build_number }
      raise "Build #{build_number} not found for project #{project.project_name} (#{project_id})" if build.nil?

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
          current_artifact.type.include?("log") && current_artifact.reference.end_with?("fastlane.log")
        end

        if build_log_artifact
          artifact_file_content = File.read(build_log_artifact.provider.retrieve!(artifact: build_log_artifact))
          existing_rows = convert_ansi_to_html(artifact_file_content.gsub("\n", "<br />"))
        else
          raise "Couldn't load previous output for build #{build_number}"
        end
      end

      # the `build_complete` line is not 100% accurate, but good enough for now.
      # This assumes we clean up build_runners https://github.com/fastlane/ci/issues/496

      locals = {
        project: project,
        build: build,
        title: "Project #{project.project_name}, Build #{build.number}",
        existing_rows: existing_rows,
        build_complete: current_build_runner.nil?
      }
      erb(:build, locals: locals, layout: FastlaneCI.default_layout)
    end

    # convert .log files that include the color information as ANSI code
    # back to HTML code that can be rendered by the user's browser
    # We probably want to re-visit this in the future, but for now it's good
    def convert_ansi_to_html(data)
      COLOR_MAPPING.each do |k, v|
        data.gsub!(/\e\[#{k}m/, "<span style=\"color:#{v}\">")
      end
      return data.gsub(/\e\[0m/, "</span>")
    end
  end
end
