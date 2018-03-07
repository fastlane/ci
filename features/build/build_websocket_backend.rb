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

        url_details = fetch_build_details(event)
        build_number = url_details[:build_number]
        project_id = url_details[:project_id]

        self.websocket_clients[project_id] ||= {}
        self.websocket_clients[project_id][build_number] ||= []
        self.websocket_clients[project_id][build_number] << ws

        current_build_runner = Services.build_runner_service.find_build_runner(
          project_id: project_id,
          build_number: build_number
        )

        # TODO: Think this through, do we properly add new listener, and notify them of line changes, etc.
        #       Also how does the "offboarding" of runners work once the tests are finished
        current_build_runner.add_listener(proc do |row|
          # TODO: Add auth check here, so a user isn't able to get the log from another build
          ws.send(row.to_json)
        end)
      end

      ws.on(:message) do |event|
        # We don't use this right now
        logger.debug([:message, event.data])
      end

      ws.on(:close) do |event|
        logger.debug([:close, ws.object_id, event.code, event.reason])

        url_details = fetch_build_details(event)
        build_number = url_details[:build_number]
        project_id = url_details[:project_id]

        self.websocket_clients[project_id][build_number].delete(ws)
        ws = nil
      end

      # Return async Rack response
      return ws.rack_response
    end
  end
end
