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
        GRPC::RpcServer.new.tap do |server|
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

      ##
      # spawns a command using popen2e. Merging stdout and stderr,
      # because its easiest to return the lazy stream when both stdout and stderr pipes are together.
      # otherwise, we run the risk of deadlock if we dont properly flush both pipes as per:
      # https://ruby-doc.org/stdlib-2.1.0/libdoc/open3/rdoc/Open3.html#method-c-popen3
      #
      # @input FastlaneCI::Agent::Command
      # @output Enumerable::Lazy<FastlaneCI::Agent::Log> A lazy enumerable with log lines.
      def spawn(command, _call)
        logger.info("spawning process with command: #{command.bin} #{command.parameters}, env: #{command.env.to_h}")
        stdin, stdouterr, wait_thrd = Open3.popen2e(command.env.to_h, command.bin, *command.parameters)
        stdin.close

        logger.info("spawned process with pid: #{wait_thrd.pid}")

        output_enumerator = ProcessOutputEnumerator.new(stdouterr, wait_thrd)
        # convert every line from io to a Log object in a lazy stream
        output_enumerator.lazy.flat_map do |line, status|
          # proto3 doesn't have nullable fields, afaik
          log = FastlaneCI::Proto::Log.new(message: (line || NULL_CHAR), status: (status || 0))
          FastlaneCI::Proto::InvocationResponse.new(log: log)
        end
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
