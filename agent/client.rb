require_relative "agent"

module FastlaneCI
  module Agent
    ##
    # A sample client that can be used to make a request to the server.
    class Client
      def initialize(host)
        @stub = Stub.new("#{host}:#{PORT}", :this_channel_is_insecure)
      end

      def request_spawn(bin, *params, env: {})
        command = Command.new(bin: bin, parameters: params, env: env)
        @stub.spawn(command)
      end
    end
  end
end
