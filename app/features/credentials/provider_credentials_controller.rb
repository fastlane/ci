require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  # A CRUD controller to manage provider credentials associated with a user. A
  # `ProviderCredential` is a credential a user may use to access some third-party
  # provider. For instance, the `GitHubProviderCredential` allows FastlaneCI users
  # to interact with the GitHub API
  class ProviderCredentialsController < AuthenticatedControllerBase
    HOME = "/provider_credentials_erb"

    post "#{HOME}/create" do
      if valid_params?(params, post_parameter_list_for_validation) &&
         user_exists_with_id?(params[:user_id])
        Services.user_service.create_provider_credential!(
          format_params(params, post_parameter_list_for_validation)
        )
      end

      redirect(HOME)
    end

    post "#{HOME}/update" do
      if valid_params?(params, post_parameter_list_for_validation) &&
         user_exists_with_id?(params[:user_id])
        Services.user_service.update_provider_credential!(
          format_params(params, post_parameter_list_for_validation)
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
      return Services.user_service.users
    end

    # Maps users and credentials hash:
    # { user.id => user.provider_credentials }
    #
    # @return [Hash]
    def user_credentials
      return users
             .map { |user| [user.id, user.provider_credentials] }
             .to_h
    end

    # Empty provider credential for use in `/create` action form. The
    # forms/_provider_credential.erb form requires that a `ProviderCredential`
    # object is passed into the form
    #
    # @return [GitHubProviderCredential]
    def blank_credential_for_create_action_form
      @new_credential ||= GitHubProviderCredential.new
    end

    #####################################################
    # @!group Locals: View-specific locals
    #####################################################

    # @return [Set[Symbol]]
    def post_parameter_list_for_validation
      return Set.new(%w(user_id id email api_token full_name))
    end

    #####################################################
    # @!group Validations: Controller validations
    #####################################################

    # @param  [String] user_id
    # @return [Boolean]
    def user_exists_with_id?(user_id)
      return users.map(&:id).include?(user_id)
    end
  end
end
