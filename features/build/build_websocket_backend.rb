require "faye/websocket"
require_relative "../../shared/logging_module"

Faye::WebSocket.load_adapter("thin")

module FastlaneCI
  # Responsible for the real-time streaming of the build output
  # to the user's browser
  # This is a Rack middleware, that is called before any of the Sinatra code is called
  # it allows us to have the real time web socket connection. Inside the `.call` method
  # we check if the current request is a socket connection or traditional HTTPs
  class BuildWebsocketBackend
    include FastlaneCI::Logging

    KEEPALIVE_TIME = 30 # in seconds

    # A hash of connected web sockets, the key being the project ID, and then the build number
    attr_accessor :websocket_clients

    def initialize(app)
      logger.debug("Setting up new BuildWebsocketBackend")
      @app = app

      self.websocket_clients = {}
    end

    def fetch_build_details(event)
      url = event.target.url
      parameters = Rack::Utils.parse_query(url)

      return {
        project_id: parameters["project"],
        build_number: parameters["build"].to_i
      }
    end

    def call(env)
      unless Faye::WebSocket.websocket?(env)
        # This is a regular HTTP call (no socket connection)
        # so just redirect to the user's app
        return @app.call(env)
      end

      ws = Faye::WebSocket.new(env, nil, { ping: KEEPALIVE_TIME })
      ws.on(:open) do |event|
        logger.debug([:open, ws.object_id])

        build_number = fetch_build_details(event)[:build_number]
        project_id = fetch_build_details(event)[:project_id]

        self.websocket_clients[project_id] ||= {}
        self.websocket_clients[project_id][build_number] ||= []
        self.websocket_clients[project_id][build_number] << ws

        TestRunnerService.test_runner_services.each do |test_runner_service|
          next if test_runner_service.current_build.number != build_number
          next if test_runner_service.project.id != project_id

          # TODO: Think this through, do we properly add new listener, and notify them of line changes, etc.
          #       Also how does the "offboarding" of runners work once the tests are finished
          test_runner_service.add_listener(proc do |row|
            web_sockets = self.websocket_clients[project_id][build_number]
            logger.debug("Streaming #{row} to #{web_sockets.count} client(s)")

            web_sockets.each do |current_socket|
              # TODO: Add auth check here, so a user isn't able to get the log from another build
              current_socket.send(row.to_json)
            end
          end)
        end
      end

      ws.on(:message) do |event|
        # We don't use this right now
        logger.debug([:message, event.data])
      end

      ws.on(:close) do |event|
        logger.debug([:close, ws.object_id, event.code, event.reason])

        build_id = fetch_build_id(event)

        self.websocket_clients[build_id].delete(ws)
        ws = nil
      end

      # Return async Rack response
      return ws.rack_response
    end
  end
end
