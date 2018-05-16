require_relative "../shared/controller_base"
require_relative "json_controller"
require_relative "../features/build_runner/remote_runner"

module FastlaneCI
  # Controller responsible of handling the login process using JWT token.
  class BuildsController < Sinatra::Base # TODO: figure out how to subclass BaseController
    include JSONController
    HOME = "/api/projects/:project_id/builds"

    post HOME do
      # unless manual_triggers_allowed?
      #  json({error: "Cannot build. There is no manual build trigger, for this branch, associated with this project."})
      #  halt(403) # Forbidden
      # end

      runner = RemoteRunner.new() # params[:project_id]
      build_id = Services.build_runner_service.add_build_runner(build_runner: runner)

      redirect(HOME.to_s)
    end

    get HOME do
      json({
        builds: current_project.builds.map do |b|
          {
            number: b.number
          }
        end
      })
    end

    get "#{HOME}/:build_id" do
      json({
        build: {
          number: current_build.number
        }
      })
    end

    get "#{HOME}/:build_id/log.ws" do
      halt(415) unless Faye::WebSocket.websocket?(request.env) # media type not supported
      halt(404) unless File.exist?("/tmp/fastlane-ci.log")

      ws = Faye::WebSocket.new(request.env)
      file = File.open("/tmp/fastlane-ci.log", "r")

      ws.on(:open) do |event|
        Thread.new do
          loop do
            begin
              Thread.pass if file.eof?

              line = file.readline
              if line == "\4"
                ws.close(1000, 'End of Transmission')
                next
              end

              ws.send(line)

            # File#readline raises EOFError if there is nothing left to read.
            rescue EOFError
              # if we read the whole file, wait a little until we try again.
              # look into using IO::select
              sleep(0.1)
              next

            # file handle has been closed.
            rescue IOError
              break
            end
          end
        end
      end

      ws.on(:message) do |msg|
        ws.send(file.pos)
      end

      ws.on(:close) do |event|
        file.close
      end

      ws.rack_response
    end

    def current_project
      @current_project ||= FastlaneCI::Services.project_service.project_by_id(params[:project_id]) or halt(404)
    end

    def current_build
      @current_build ||= current_project.builds.find { |b| b.number == build_number } or halt(404)
    end

    def manual_triggers_allowed?
      current_project.job_triggers.any? do |trigger|
        trigger.type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual]
      end
    end
  end
end
