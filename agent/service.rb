require "open3"
require_relative "agent"
require_relative "invocation"

module FastlaneCI
  module Agent
    ##
    # A simple implementation of the agent service.
    class Service < FastlaneCI::Proto::Agent::Service
      include FastlaneCI::Agent::Logging

      ##
      # returns a configured GRPC server ready to listen for connections.
      def self.server
        channel_params = {
          "grpc.enable_retries" => 1,
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
        GRPC::RpcServer.new(server_args: channel_params).tap do |server|
          server.add_http2_port("#{HOST}:#{PORT}", :this_port_is_insecure)
          server.handle(new)
        end
      end

      def initialize
        # fastlane actions are not thread-safe and we must not run more than 1 at a time.
        @busy = false
      end

      def busy?
        @busy
      end

      def run_fastlane(invocation_request, _call)
        command = invocation_request.command
        logger.info("RPC run_fastlane: #{command.bin} #{command.parameters}, env: #{command.env.to_h}")
        Enumerator.new do |yielder|
          invocation = Invocation.new(invocation_request, yielder)
          if busy?
            invocation.reject(RuntimeError.new("I am busy"))
            next
          end
          begin
            @busy = true
            invocation.run
          rescue StandardError => exception
            invocation.throw(exception)
          ensure
            @busy = false
          end
          begin
            while true do
              puts ".."
              log = FastlaneCI::Proto::Log.new(message: "..", timestamp: Time.now.to_i)
              yielder << FastlaneCI::Proto::InvocationResponse.new(log: log)
              sleep(1)
            end
          rescue StandardError => exception
            puts exception
          end          
        end
      end
      # Service
    end
    # Agent
  end
  # FastlaneCI
end

if $0 == __FILE__
  server = FastlaneCI::Agent::Service.server

  Signal.trap("SIGINT") do
    Thread.new { server.stop }.join # Mutex#synchronize can't be called in trap context. Put it on a thread.
  end

  puts("Agent (#{FastlaneCI::Agent::VERSION}) is running on #{FastlaneCI::Agent::HOST}:#{FastlaneCI::Agent::PORT}")
  server.run_till_terminated
end
