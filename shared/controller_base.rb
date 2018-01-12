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
  # Handles default configuration like auto-reloading, session management, and erb path correcting
  #
  class ControllerBase < Sinatra::Base
    include FastlaneCI::Logging

    # I don't like this here, I'd rather use the mixin for organization, but that isn't done
    # TODO: use mixin
    configure :development do
      register Sinatra::Reloader
    end

    class << self
      attr_accessor :_file
    end

    def self.inherited(obj)
      super(obj)
      # __FILE__ returns the file we're in (always controller_base.rb in this case)
      # We actually want the file that inherited this class
      # When this class inherited, we set a new variable which contains the __FILE__ of the subclass
      obj._file = caller(1..1).first[/^[^:]+/]
    end

    def initialize(app = nil)
      # Always expect HOME to be defined, if not, we need to fail on startup
      raise "#{self} missing `HOME` variable" unless defined?(self.class::HOME)

      setup_common_controller_configuration
      super(app)
    end

    # setup all the common configuration required for the controller,
    # this includes various sinatra specific things
    def setup_common_controller_configuration(is_called_during_reload: false)
      # by default, the erb root incorrectly uses __FILE__ and it picks up the wrong directory
      # we need to correct that here
      erb_root = File.dirname(self.class._file)
      logger.debug("setting erb root to #{erb_root}")
      self.class.set(:root, erb_root)

      # /dashboard and /dashboard/ should route the same
      logger.debug("turning off strict paths")
      self.class.set(:strict_paths, false)

      # enable access to the session in this class
      logger.debug("enabling sessions")
      self.class.enable(:sessions)

      # TODO: Ideally we figure out how to get this working, but for now things work
      # unless is_called_during_reload
      #   enable_resource_reloading(file_path: self.class._file) {
      #     logger.debug("Doing my thing")
      #     setup_common_controller_configuration(is_called_during_reload: true)
      #   }
      # end
    end
  end
end
