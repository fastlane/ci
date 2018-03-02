require "faye/websocket"
require_relative "../../shared/logging_module"

Faye::WebSocket.load_adapter('thin')

module FastlaneCI
  # Responsible for the real-time streaming of the build output
  # to the user's browser
  class BuildWebsocketBackend
    include FastlaneCI::Logging

    KEEPALIVE_TIME = 30 # in seconds
    CHANNEL = "build-output"

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

        # TODO: Testing code only
        # We don't want to actually trigger the runner here
        FastlaneCI::FastlaneTestRunner.new.run(
          lane: "beta",
          platform: "ios"
        ) do |row|
          # Additionally to transfering the original metadata of this message
          # that look like this:
          # 
          # {:type=>:success, :message=>"Everything worked"}
          # 
          # we append the HTML code that should be used in the `html` key
          # the result looks like this
          #
          # {"type":"success","message":"Driving the lane 'ios beta' 🚀","html":"<p class=\"success\">Driving the lane 'ios beta' 🚀</p>"}
          #
          
          row[:html] = FastlaneOutputToHtml.convert_row(row)
          logger.debug("Streaming #{row} to #{@clients.count} client(s)")
          @clients.each do
            ws.send(row.to_json)
          end
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
