require "sinatra/custom_logger"
require "logger"

module FastlaneCI
  # Logging mixin, can be used wherever
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

          thread_id = ""

          if ENV["super_verbose"]
            # this gets noisey really quickly
            thread_id = " #{Thread.current[:thread_id]}" unless Thread.current[:thread_id].nil?
          end

          "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}#{thread_id}] #{severity} #{class_name}:  #{msg}\n"
        end
      end
      return @logger
    end
  end
end
