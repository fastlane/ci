require "faye/websocket"
require_relative "../../shared/logging_module"

Faye::WebSocket.load_adapter('thin')

module FastlaneCI
  class BuildWebsocketBackend
    include FastlaneCI::Logging

    KEEPALIVE_TIME = 30 # in seconds
    CHANNEL = "build-output"

    def initialize(app)
      @app = app

      @clients = []
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
        ws.on :open do |event|
          logger.debug([:open, ws.object_id])
          @clients << ws


          # TODO: Testing code only
          FastlaneCI::FastlaneTestRunner.new.run(
            lane: "beta",
            platform: "ios"
          ) do |row|
            html_row = FastlaneOutputToHtml.convert_row(row)
            puts html_row
            @clients.each do
              ws.send(html_row)
            end
          end
        end

        ws.on :message do |event|
          # We don't use this right now
          logger.debug([:message, event.data])
        end

        ws.on :close do |event|
          logger.debug([:close, ws.object_id, event.code, event.reason])
          @clients.delete(ws)
          ws = nil
        end

        # Return async Rack response
        ws.rack_response
      else
        @app.call(env)
      end
    end
  end
end
