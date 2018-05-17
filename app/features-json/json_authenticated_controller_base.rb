require_relative "../shared/controller_base"
require_relative "../shared/logging_module"
require_relative "../services/config_service"
require_relative "../services/services"
require_relative "./middleware/jwt_auth"

module FastlaneCI
  #
  # A user is required to be logged in to access any routes on this controller
  #
  class JSONAuthenticatedControllerBase < ControllerBase
    use FastlaneCI::JwtAuth
    include FastlaneCI::Logging

    # Method to obtain the current user given their primary key.
    # @return [User]
    def current_user
      user = FastlaneCI::Services.user_service.find_user(id: env[:user])
      if user.nil?
        halt(500)
      else
        return user
      end
    end

    def current_user_config_service
      @user_config_service = FastlaneCI::ConfigService.new(ci_user: current_user)
      return @user_config_service
    end

    def check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])
      provider_credential = current_user.provider_credential(type: type)
      raise "User #{current_user.email} doesn't have any linked `#{type}` accounts" if provider_credential.nil?
      return provider_credential
    end

    def user_project_with_id(project_id: nil)
      project = FastlaneCI::Services.project_service.project_by_id(project_id)
      raise "User #{current_user.email} doesn't have access to a project with id `#{project_id}`" if project.nil?
      return project
    end
  end
end
