require_relative "build_service"

module FastlaneCI
  # All services available to the app
  class Services
    BUILD_SERVICE = FastlaneCI::BuildService.new
  end
end
