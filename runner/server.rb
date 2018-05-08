require "logger"
require "open3"
require_relative "runner"

module FastlaneCI
  module Runner
    ##
    # A simple implementation of the runner service.
    class Server < Service
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
        _stdin, stdouterr, wait_thrd = Open3.popen2e(command.env.to_h, command.bin, *command.parameters)
        @logger.info("spawned process with pid: #{wait_thrd.pid}")

        # convert every line from stdout to a Log object in a lazy stream
        stdouterr.each_line.lazy.flat_map do |line|
          Log.new(message: line)
        end
        # ensure
        # TODO: figure out how we are supposed to close these handles.
        # doing so in the ensure block, breaks our connection
        # stdin.close
        # stdout.close
      end
    end
  end
end

# rubocop:disable all
if $0 == __FILE__
  include FastlaneCI::Runner
  # TODO.. catch signals, make sure we clean up, etc.
  server = Server.server

  # TODO: unify logger
  puts("Server is running on #{HOST}:#{PORT}")
  server.run_till_terminated
end
