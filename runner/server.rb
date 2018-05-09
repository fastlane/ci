require "logger"
require "open3"
require_relative "runner"

module FastlaneCI
  module Runner
    ##
    # A simple implementation of the runner service.
    class Server < Service
      ##
      # this class is used to create a lazy enumerator
      # that will yield back lines from the stdout/err of the process
      # as well as the exit status when it is complete.
      class ProcessEnumerator
        def initialize(io, thread)
          @io = io
          @thread = thread
        end

        def generator
          Enumerator.new do |y|
            y.yield(@io.gets) while @thread.alive?
            @io.close
            y.yield(nil, @thread.value.exitstatus)
          end
        end
      end

      def self.server
        GRPC::RpcServer.new.tap do |s|
          s.add_http2_port("#{HOST}:#{PORT}", :this_port_is_insecure)
          s.handle(new)
        end
      end

      def initialize
        @logger = Logger.new(STDOUT)
      end

      ##
      # spawns a command using popen2e. Merging stdout and stderr,
      # because its easiest to return the lazy stream when both stdout and stderr pipes are together.
      # otherwise, we run the risk of deadlock if we dont properly flush both pipes as per:
      # https://ruby-doc.org/stdlib-2.1.0/libdoc/open3/rdoc/Open3.html#method-c-popen3
      #
      # @input FastlaneCI::Runner::Command
      # @output Enumerable::Lazy<FastlaneCI::Runner::Log> A lazy enumerable with log lines.
      def spawn(command, _call)
        @logger.info("spawning process with command: #{command.bin} #{command.parameters}, env: #{command.env.to_h}")
        stdin, stdouterr, wait_thrd = Open3.popen2e(command.env.to_h, command.bin, *command.parameters)
        stdin.close

        @logger.info("spawned process with pid: #{wait_thrd.pid}")

        process_enumerator = ProcessEnumerator.new(stdouterr, wait_thrd)
        # convert every line from io to a Log object in a lazy stream
        process_enumerator.generator.lazy.flat_map do |line, status|
          # proto3 doesn't have nullable fields, afaik
          Log.new(message: (line || ""), status: (status || 0))
        end
      end
    end
  end
end

# rubocop:disable all
if $0 == __FILE__
  include FastlaneCI::Runner

  server = Server.server

  Signal.trap("SIGINT") do
    Thread.new { server.stop }.join # Mutex#synchronize can't be called in trap context. Put it on a thread.
  end

  # TODO: unify logger
  puts("Server is running on #{HOST}:#{PORT}")
  server.run_till_terminated
end
