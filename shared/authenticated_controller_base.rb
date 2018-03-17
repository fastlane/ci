require_relative "models/provider_credential"
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
        logger.debug("No user_config_service for #{self.user.email}, creating one")
        @user_config_service = FastlaneCI::ConfigService.new(ci_user: self.user, clone_user_provider_credential: check_and_get_provider_credential)
      end
      return @user_config_service
    end

    # assume we need a user's provider credential for GitHub, realy though, a provider credential type should come from the controller
    def check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])
      provider_credential = self.user.provider_credential(type: type)
      raise "User #{self.user.email} doesn't have any linked `#{type}` accounts" if provider_credential.nil?
      return provider_credential
    end

    def user_project_with_id(project_id: nil)
      project = FastlaneCI::Services.project_service.project_by_id(project_id)
      raise "User #{self.user.email} doesn't have access to a project with id `#{project_id}`" if project.nil?
      return project
    end
  end
end
