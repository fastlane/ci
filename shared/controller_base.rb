require "sinatra/base"
require "sinatra/reloader"
require "sinatra/custom_logger"
require "logger"

require_relative "logging_module"
require_relative "resource_reloader.rb"
require_relative "../services/services"

module FastlaneCI
  #
  # Base class for all controllers
  #
  class ControllerBase < Sinatra::Base
    include FastlaneCI::Logging

    # I don't like this here, I'd rather use the mixin for organization, but that isn't done
    configure :development do
      register Sinatra::Reloader
    end

    class << self
      attr_accessor :_file
    end

    def self.inherited(obj)
      super(obj)
      obj._file = caller(1..1).first[/^[^:]+/]
    end

    def home_route
      return self.class::HOME
    end

    def initialize(app = nil)
      raise "#{self} missing `HOME` variable" unless defined?(self.class::HOME)

      setup_common_controller_configuration
      add_common_routes(app)
      super(app)
    end

    def setup_common_controller_configuration(is_called_during_reload: false)
      erb_root = File.dirname(self.class._file)
      logger.debug("setting erb root to #{erb_root}")
      self.class.set(:root, erb_root)

      logger.debug("turning off strict paths")
      self.class.set(:strict_paths, false)

      logger.debug("enabling sessions")
      self.class.enable(:sessions)

      # # this doesn't work, just yet
      # unless is_called_during_reload
      #   enable_resource_reloading(file_path: self.class._file) {
      #     logger.debug("Doing my thing")
      #     setup_common_controller_configuration(is_called_during_reload: true)
      #   }
      # end
    end

    def add_common_routes(app)
    end
  end
end
