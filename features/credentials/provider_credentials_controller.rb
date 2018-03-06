require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  # A CRUD controller to manage provider credentials associated with a user
  class ProviderCredentialsController < AuthenticatedControllerBase
    HOME = "/provider_credentials"

    get HOME do
      locals = { title: "Provider Credentials" }
      erb(:provider_credentials, locals: locals, layout: FastlaneCI.default_layout)
    end

    post "#{HOME}/create" do
      if valid_params?(params, provider_credential_params) &&
         valid_user_id?(params[:user_id])
        Services.provider_credential_service.create_provider_credential!(
          format_params(params, provider_credential_params)
        )
      end

      redirect(HOME)
    end

    post "#{HOME}/update" do
      if valid_params?(params, provider_credential_params) &&
         valid_user_id?(params[:user_id])
        Services.provider_credential_service.update_provider_credential!(
          format_params(params, provider_credential_params)
        )
      end

      redirect(HOME)
    end

    private

    #####################################################
    # @!group Data: View-specific data
    #####################################################

    # @return [Array[User]]
    def users
      Services.user_service.user_data_source.users
    end

    # Maps users and credentials hash:
    # { user.id => user.provider_credentials }
    #
    # @return [Hash]
    def user_credentials
      users
        .map { |user| [user.id, user.provider_credentials] }
        .to_h
    end

    # Empty provider credential
    #
    # @return [GitHubProviderCredential]
    def new_credential
      @new_credential ||= GitHubProviderCredential.new
    end

    #####################################################
    # @!group Locals: View-specific locals
    #####################################################

    # @return [Set[Symbol]]
    def provider_credential_params
      Set.new(%w(user_id id email api_token provider_name type full_name))
    end

    #####################################################
    # @!group Validations: Controller validations
    #####################################################

    # Validates that the user you're trying to associate the credential with
    # exists
    #
    # @param  [String] user_id
    # @return [Boolean]
    def valid_user_id?(user_id)
      users.map(&:id).include?(user_id)
    end
  end
end
