require_relative "models/provider"
require_relative "controller_base"
require_relative "logging_module"
require_relative "authentication_request_checker"
require_relative "../services/config_service"

module FastlaneCI
  #
  # A user is required to be logged in to access any routes on this controller
  #
  class AuthenticatedControllerBase < ControllerBase
    register AuthenticatedRequestChecker
    include FastlaneCI::Logging

    def initialize(app)
      super(app)

      self.class.ensure_logged_in
    end

    def user
      return session[:user]
    end

    def current_user_config_service
      if @user_config_service.nil?
        logger.debug("no user_config_service for #{self.user}, creating one")
        @user_config_service = FastlaneCI::ConfigService.new(ci_user: self.user)
      end
      return @user_config_service
    end

    # assume we need a user's provider for GitHub, realy though, a provider type should come from the controller
    def check_and_get_provider(type: FastlaneCI::Provider::PROVIDER_TYPES[:github])
      provider = self.user.provider(type: type)
      raise "user #{self.user.email} doesn't have any linked `#{type}` accounts" if provider.nil?
      return provider
    end

    def user_project_with_id(project_id: nil)
      provider = self.check_and_get_provider
      project = self.current_user_config_service.project(id: project_id, provider: provider)
      raise "user #{self.user.email} doesn't have access to a project with id `#{project_id}`" if project.nil?
      return project
    end
  end
end
