require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  # A CRUD controller to manage provider credentials associated with a user
  class ProviderCredentialsController < AuthenticatedControllerBase
    HOME = "/provider_credentials"

    post "#{HOME}/create" do
      if valid_params?(params, provider_credential_params)
        Services.provider_credential_service.create_provider_credential!(params)
      end

      redirect back
    end

    post "#{HOME}/update" do
      if valid_params?(params, provider_credential_params)
        Services.provider_credential_service.update_provider_credential!(params)
      end

      redirect back
    end

    private

    #####################################################
    # @!group Locals: View-specific locals
    #####################################################

    # @return [Set[Symbol]]
    def provider_credential_params
      Set.new(%w(user_id id email api_token provider_name type full_name))
    end
  end
end
