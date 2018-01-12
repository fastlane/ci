require_relative "build_service"
require_relative "config_service"
require_relative "code_hosting_service"

module FastlaneCI
  # All services available to the app
  class Services
    BUILD_SERVICE = FastlaneCI::BuildService.new
    CONFIG_SERVICE = FastlaneCI::ConfigService.new
    # CODE_HOSTING_SERVICE = FastlaneCI::CodeHostingService.new # this doesn't work for arrays

    class << self
      # Hosts an array of code hosting sources
      # Similar to the constants above
      # but in the future we'll support more than GitHub, so we store them in an array
      # TODO: This is just temporary, as this won't actually store the session anywhere
      # We'll have to store the session in the Keychain, as they're important GitHub API tokens
      # This part has to be rewritten, consult with @taquitos
      def code_hosting_sources
        @code_hosting_sources ||= []
      end
    end
  end
end
