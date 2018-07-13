require_relative "../../shared/logging_module"
require_relative "build_runner_change_listener"
module FastlaneCI
  # Build Runner Change Listener for websocket connection (expecting `faye/websocket`)
  class WebSocketBuildRunnerChangeListener < BuildRunnerChangeListener
    include FastlaneCI::Logging

    def initialize(web_socket:)
      @web_socket = web_socket
      @done_listening = false
    end

    def done_listening?
      return @done_listening
    end

    def connection_closed
      @done_listening = true
      @web_socket = nil
    end

    def row_received(row)
      if @web_socket.nil?
        logger.error("@web_socket is nil, we can't send anything to it")
        connection_closed
        return
      end

      unless @web_socket.send(row.to_json)
        # TODO: CRITICAL: Add auth check here, so a user isn't able to get the log from another build
        # TODO: should we call `connection_closed` or is this recoverable?
        logger.error("Something failed when sending the current row via a web socket connection")
      end
    end
  end
end
