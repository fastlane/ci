require_relative "agent"

# A module encapsulating fastlane.ci agent code.
module FastlaneCI
  module Agent
    ##
    # A sample client that can be used to make a request to the service.
    class Client

      attr_reader :channel
      def initialize(host)
        channel_params = {
          "grpc.enable_retries" => 1,
          "grpc.http2.max_pings_without_data" => 0,
          "grpc.http2.max_ping_strikes" => 0,
          "grpc.max_concurrent_streams" => 1,
          "grpc.max_connection_idle_ms" => 3600000,
          "grpc.max_connection_age_ms" => 3600000,
          "grpc.dns_min_time_between_resolutions_ms" => 150,
          "grpc.grpclb_call_timeout_ms" => 3600000,
          "grpc.grpclb_fallback_timeout_ms" => 3600000,
          "grpc.min_reconnect_backoff_ms" => 200,
          "grpc.max_reconnect_backoff_ms" => 250,
          "grpc.keepalive_time_ms" => 1000,
          "grpc.keepalive_timeout_ms" => 3600000,
          "grpc.keepalive_permit_without_calls" => 1,
          "grpc.initial_reconnect_backoff_ms" => 1000 
        }
        @channel = GRPC::Core::Channel.new("#{host}:#{PORT}", channel_params, :this_channel_is_insecure)
        @stub = Proto::Agent::Stub.new("#{host}:#{PORT}", :this_channel_is_insecure, channel_override:@channel)
      end

      def request_spawn(bin, *params, env: {})
        command = Proto::Command.new(bin: bin, parameters: params, env: env)
        @stub.spawn(command)
      end

      def request_run_fastlane(bin, *params, env: {})
        command = Proto::Command.new(bin: bin, parameters: params, env: env)
        @stub.run_fastlane(Proto::InvocationRequest.new(command: command))
      end
    end
  end
  @file && @file.close
end

if $0 == __FILE__
  client = FastlaneCI::Agent::Client.new("207.254.45.125")
  env = {
    "FASTLANE_CI_ARTIFACTS" => "artifacts",
    "GIT_URL" => "https://github.com/bogdanbrato/ios-themoji",
    "GIT_SHA" => "03f4779d11595f41bb7f1959c33645724c54aed6"
  }
  response = client.request_run_fastlane(
    "bundle", "exec", "fastlane", "ios", "test", env: env
  )

  thread = Thread.new do
    while true do
      puts "=== Channel Watcher: connectivity_state = #{client.channel.connectivity_state}"
      sleep(1.0)
    end
  end
  
  thread2 = Thread.new do
    while true do
      client.request_run_fastlane("echo", "healthcheck")
      sleep(1.0)
    end
  end

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
  thread.exit
  thread2.exit
end
