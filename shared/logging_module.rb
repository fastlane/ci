require "sinatra/custom_logger"
require "logger"

module FastlaneCI
  # Logging mixin, can be used wherever
  #
  #
  # The available log levels are:
  #   * UNKNOWN - An unknown message that should always be logged.
  #   * FATAL - An unhandleable error that results in a program crash.
  #   * ERROR - A handleable error condition
  #   * WARN - A warning
  #   * INFO - Generic (useful) information about system operation
  #   * DEBUG - Low-level information for developers
  #
  # from most-severe to least.
  #
  # The default log level is WARN, so anything more severe than a warning will be logged out.
  #
  # Setting the environment variable `DEBUG=1` will lower the log level to INFO.
  # `logger.info` should be used to print out generic (and useful) information about
  # system operation.
  #
  # Setting the environment variable `FASTLANE_CI_SUPER_VERBOSE=1` further lowers the log to DEBUG.
  # This includes extra logging which includes thread ids, and other
  # non-essential information that could be useful during debugging.
  #
  # Use `logger.debug` for exposing this extra information
  module Logging
    def logger
      @logger ||= Logger.new(STDOUT).tap do |logger|
        logger.formatter = proc do |severity, datetime, progname, msg|
          # assume we're coming from an instance of a class
          class_name = self.class.name.split("::").last
          if class_name == "Class"
            # bad assumption, we're coming from a class method
            class_name = self.name.split("::").last
          end

          progname ||= class_name

          thread_id = ""

          if ENV['FASTLANE_CI_SUPER_VERBOSE']
            # this gets noisey really quickly
            thread_id = " #{Thread.current[:thread_id]}" unless Thread.current[:thread_id].nil?
          end

          "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}#{thread_id}] #{severity} #{progname}:  #{msg}\n"
        end

        logger.level = :warn
        logger.level = :debug if ENV['DEBUG']
        logger.level = :debug if ENV['FASTLANE_CI_SUPER_VERBOSE']
      end

      return @logger
    end
  end
end
