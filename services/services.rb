require_relative "build_service"
require_relative "config_service"
require_relative "code_hosting_service"
require_relative "git_repo"

module FastlaneCI
  # All services available to the app
  class Services
    BUILD_SERVICE = FastlaneCI::BuildService.new
    CONFIG_SERVICE = FastlaneCI::ConfigService.new
  end
end
