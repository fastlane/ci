require_relative "../../shared/authenticated_controller_base"
require "pathname"
require "sinatra-websocket"

module FastlaneCI
  # Controller for a single project view. Responsible for updates, triggering builds, and displaying project info
  class BuildController < AuthenticatedControllerBase
    HOME = "/projects/*/builds"

    get "/projects/*/builds/*" do |project_id, build_id|
      project = self.user_project_with_id(project_id: project_id)
      build = project.builds.find { |b| b.sha == build_id } # TODO: We need a build ID, sha isn't enough

      locals = {
        project: project,
        build: build,
        title: "Project #{project.project_name}, Build #{build.sha}"
      }
      erb(:build, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "/projects*/builds/*/stream" do |project_id, build_id|
      if request.websocket?
        request.websocket do |ws|
          ws.onopen do
            ws.send("Hello World!")
            settings.sockets << ws
          end
          ws.onmessage do |msg|
            EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
          end
          ws.onclose do
            warn("websocket closed")
            settings.sockets.delete(ws)
          end
        end
      else
        require 'pry'; binding.pry
        puts 'hi'
      end
    end
  end
end
