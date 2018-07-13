require "faye/websocket"
require_relative "../../shared/logging_module"
require_relative "../build_runner/web_socket_build_runner_change_listener"

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

    def call(env)
      unless Faye::WebSocket.websocket?(env)
        # This is a regular HTTP call (no socket connection)
        # so just redirect to the user's app
        return @app.call(env)
      end

      ws = Faye::WebSocket.new(env, nil, { ping: KEEPALIVE_TIME })
      web_socket_build_runner_change_listener = WebSocketBuildRunnerChangeListener.new(web_socket: ws)

      ws.on(:open) do |event|
        logger.debug([:open, ws.object_id])

        request_params = Rack::Request.new(env).params
        build_number = request_params["build_number"].to_i
        project_id = request_params["project_id"]

        websocket_clients[project_id] ||= {}
        websocket_clients[project_id][build_number] ||= []
        websocket_clients[project_id][build_number] << ws

        current_build_runner = Services.build_runner_service.find_build_runner(
          project_id: project_id,
          build_number: build_number
        )
        next if current_build_runner.nil? # this is the case if the build was run a while ago

        # TODO: Think this through, do we properly add new listener, and notify them of line changes, etc.
        #       Also how does the "offboarding" of runners work once the tests are finished
        current_build_runner.add_build_change_listener(web_socket_build_runner_change_listener)
      end

      ws.on(:message) do |event|
        # We don't use this right now
        logger.debug([:message, event.data])
      end

      ws.on(:close) do |event|
        logger.debug([:close, ws.object_id, event.code, event.reason])

        request_params = Rack::Request.new(env).params
        build_number = request_params["build_number"].to_i
        project_id = request_params["project_id"]

        websocket_clients[project_id][build_number].delete(ws)
        web_socket_build_runner_change_listener.connection_closed
        ws = nil
      end

      # Return async Rack response
      return ws.rack_response
    end
  end
end
