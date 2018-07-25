require_relative "agent"

# A module encapsulating fastlane.ci agent code.
module FastlaneCI
  module Agent
    ##
    # A sample client that can be used to make a request to the service.
    class Client
      ##
      # the host that the client is connecting to
      attr_reader :host

      # the port that the client is connecting to
      attr_reader :port

      def initialize(host, port = PORT)
        @host = host
        @port = port
        @stub = Proto::Agent::Stub.new("#{@host}:#{@port}", :this_channel_is_insecure)
      end

      def request_spawn(bin, *params, env: {})
        command = Proto::Command.new(bin: bin, parameters: params, env: env)
        @stub.spawn(command)
      end

      def request_run_fastlane(bin, *params, env: {})
        command = Proto::Command.new(bin: bin, parameters: params.compact, env: env)
        @stub.run_fastlane(Proto::InvocationRequest.new(command: command))
      end
    end
  end
end

if $0 == __FILE__
  client = FastlaneCI::Agent::Client.new("localhost")
  env = {
    "FASTLANE_CI_ARTIFACTS" => "artifacts",
    "GIT_URL" => "https://github.com/snatchev/themoji-ios"
  }
  response = client.request_run_fastlane("actions", env: env)

  @file = nil
  response.each do |r|
    puts("Log: #{r.log.message}") if r.log

    puts("State: #{r.state}") if r.state != :PENDING

    puts("Error: #{r.error.description} #{r.error.stacktrace}") if r.error

    next unless r.artifact
    puts("Chunk: writing to #{r.artifact.filename}")
    @file ||= File.new(r.artifact.filename, "wb")
    @file.write(r.artifact.chunk)
  end
  @file && @file.close
end
