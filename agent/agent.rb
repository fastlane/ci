# frozen_string_literal: true

require "logger"
require "grpc"
# put ./protos in the load path. this is required because they are auto-generated and have specific `require` paths
proto_path = File.expand_path("../protos", File.dirname(__FILE__))
$LOAD_PATH << proto_path unless $LOAD_PATH.include?(proto_path)

require "agent_services_pb"

module FastlaneCI
  ##
  # Agent - The deamon that runs on a compute resource waiting to accept rpc commands and execute them.
  # It will respond with a log stream and exit status for the commands.
  module Agent
    VERSION = "0.0.0-alpha"
    HOST = "0.0.0.0"
    PORT = "8089"
    NULL_CHAR = "\0"
    EOT_CHAR = "\4" # end-of-transmission character.

    ##
    # Logging module to expose the logger.
    module Logging
      def logger
        return @logger if defined?(@logger)

        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG

        @logger
      end
    end
  end
end
