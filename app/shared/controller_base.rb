require "sinatra/base"
require "sinatra/reloader"
require "sinatra/custom_logger"
require "sinatra/flash"
require "set"
require "logger"

require_relative "logging_module"
require_relative "setup_checker"
require_relative "resource_reloader"

module FastlaneCI
  #
  # Base class for all controllers
  # Handles default configuration like auto-reloading, session management, and erb path correcting
  #
  class ControllerBase < Sinatra::Base
    enable :sessions

    register SetupChecker
    register Sinatra::Flash

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

      self.class.ensure_proper_setup
    end

    # setup all the common configuration required for the controller,
    # this includes various sinatra specific things
    def setup_common_controller_configuration(is_called_during_reload: false)
      # by default, the erb root incorrectly uses __FILE__ and it picks up the wrong directory
      # we need to correct that here
      erb_root = File.dirname(self.class._file)
      logger.debug("Setting erb root to #{erb_root}")
      self.class.set(:root, erb_root)

      # /dashboard_erb and /dashboard_erb/ should route the same
      logger.debug("Turning off strict paths")
      self.class.set(:strict_paths, false)

      # enable access to the session in this class
      logger.debug("Enabling sessions")
      self.class.enable(:sessions)

      # TODO: This should be removed once it's used in production
      # By setting a seed here, the session will persist across server restarts
      # which is extremely useful for development
      if ENV["RACK_ENV"] == "development"
        self.class.set(:session_secret, "DEVELOPMENT_ENV_FASTLANE_CI")
      end

      # TODO: use session pool for server-side storage
      # generate a secret too
      # see http://sinatrarb.com/intro.html#Using%20Sessions
      # use Rack::Session::Pool, :expire_after => 2592000
      # use Rack::Protection::RemoteToken
      # use Rack::Protection::SessionHijacking

      # TODO: Ideally we figure out how to get this working, but for now things work
      # unless is_called_during_reload
      #   enable_resource_reloading(file_path: self.class._file) {
      #     logger.debug("Doing my thing")
      #     setup_common_controller_configuration(is_called_during_reload: true)
      #   }
      # end
    end

    protected

    # Parses the JSON request body and returns a Ruby hash
    #
    # @param  [Sinatra::Request] request
    # @return [Hash]
    def parse_request_body(request)
      JSON.parse(request.body.read).symbolize_keys
    end

    # Converts keys from strings to symbols and selects only the expected keys
    #
    # @param  [Hash]       actuals
    # @param  [Set[Symbol] expected_keys
    # @return [Hash]
    def format_params(actuals, expected_keys)
      actuals
        .select { |k, _v| expected_keys.include?(k) }
        .each_with_object({}) { |(k, v), hash| hash[k.to_sym] = v }
    end

    # Validates all the required keys are present, and that no values are nil
    #
    # @param  [Hash]       actuals
    # @param  [Set[Symbol] expected_keys
    # @return [Boolean]
    def valid_params?(actuals, expected_keys)
      actuals = actuals.delete_if { |k, _v| k == "captures" }
      expected_keys == actuals.keys.to_set &&
        actuals.values.none? { |v| v.nil? || v.empty? }
    end
  end
end
