require_relative "runner"

module FastlaneCI
  module Runner
    ##
    # A sample client that can be used to make a request to the server.
    class Client
      def initialize
        @stub = Stub.new("#{HOST}:#{PORT}", :this_channel_is_insecure)
      end

      def request_spawn(bin, *params)
        command = Command.new(bin: bin, parameters: params, env: {})
        @stub.spawn(command)
      end
    end
  end
end

if $0 == __FILE__
  client = FastlaneCI::Runner::Client.new
  logs = client.request_spawn("ping", "-c", "20", "google.com")
  logs.each do |log|
    puts log.message
  end
end
