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
    HOST = "0.0.0.0".freeze
    PORT = "8080".freeze
  end
end
