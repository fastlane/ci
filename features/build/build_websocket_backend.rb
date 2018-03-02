require "faye/websocket"
require_relative "../../shared/logging_module"

Faye::WebSocket.load_adapter('thin')

module FastlaneCI
  # Responsible for the real-time streaming of the build output
  # to the user's browser
  class BuildWebsocketBackend
    include FastlaneCI::Logging

    KEEPALIVE_TIME = 30 # in seconds

    # A hash of connected web sockets, the key being the build ID # TODO: right now we still use the sha
    attr_accessor :websocket_clients

    def initialize(app)
      logger.debug("Setting up new BuildWebsocketBackend")
      @app = app

      self.websocket_clients = {}
    end

    def fetch_build_id(event)
      url = event.target.url
      parameters = Rack::Utils.parse_query(url)
      return parameters["build"]
    end

    def call(env)
      unless Faye::WebSocket.websocket?(env)
        # This is a regular HTTP call (no socket connection)
        # so just redirect to the user's app
        return @app.call(env)
      end

      ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
      ws.on(:open) do |event|
        logger.debug([:open, ws.object_id])

        build_id = fetch_build_id(event)

        self.websocket_clients[build_id] ||= []
        self.websocket_clients[build_id] << ws

        TestRunnerService.test_runner_services.each do |test_runner_service|
          next if test_runner_service.sha != build_id # TODO: mismatch of sha, unify sha/build_id

          test_runner_service.add_listener(proc do |row|
            logger.debug("Streaming #{row} to #{self.websocket_clients.count} client(s)")

            self.websocket_clients[build_id].each do |current_socket|
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
