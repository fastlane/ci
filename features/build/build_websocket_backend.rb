require "faye/websocket"
require_relative "../../shared/logging_module"

Faye::WebSocket.load_adapter('thin')

module FastlaneCI
  # Responsible for the real-time streaming of the build output
  # to the user's browser
  class BuildWebsocketBackend
    class << self
      attr_accessor :test_runner_services
    end

    include FastlaneCI::Logging

    KEEPALIVE_TIME = 30 # in seconds
    CHANNEL = "build-output" # TODO: we probably need this to distinguish between multiple builds

    def initialize(app)
      logger.debug("Setting up new BuildWebsocketBackend")
      @app = app

      @clients = []
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
        @clients << ws

        self.class.test_runner_services.each do |test_runner_service|
          logger.debug("Appending to runner service :)")
          test_runner_service.add_listener(proc do |row|
            logger.debug("Streaming #{row} to #{@clients.count} client(s)")
            @clients.each do
              ws.send(row.to_json)
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
        @clients.delete(ws)
        ws = nil
      end

      # Return async Rack response
      return ws.rack_response
    end
  end
end
