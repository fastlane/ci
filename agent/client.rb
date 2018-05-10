require_relative "agent"

module FastlaneCI
  module Agent
    ##
    # A sample client that can be used to make a request to the server.
    class Client
      def initialize(host)
        @stub = Stub.new("#{host}:#{PORT}", :this_channel_is_insecure)
      end

      def request_spawn(bin, *params)
        command = Command.new(bin: bin, parameters: params, env: {})
        @stub.spawn(command)
      end
    end
  end
end

if $0 == __FILE__
  client = FastlaneCI::Agent::Client.new("localhost")
  logs = client.request_spawn("ping", "-c", "20", "google.com")
  logs.each do |log|
    puts({ message: log.message, status: log.status, level: log.level })
  end
end
