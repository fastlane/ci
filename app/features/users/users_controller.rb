require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  # A CRUD controller to manage users
  class UsersController < AuthenticatedControllerBase
    HOME = "/users_erb"

    # When the `/users/create` form is submitted:
    #
    # - creates a user if the locals are valid
    post "#{HOME}/create" do
      if valid_params?(params, post_parameter_list_for_validation)
        Services.user_service.create_user!(
          id: params[:id],
          email: params[:email],
          password: params[:password]
        )
      end

      redirect(HOME)
    end

    # Updates a user existing in the configuration repository `users.json`
    post "#{HOME}/update" do
      if valid_params?(params, post_parameter_list_for_validation)
        new_user = User.new(
          id: params[:id],
          email: params[:email]
        )

        Services.user_service.update_user!(new_user)
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

    # Empty user object for `/create` action form. The forms/_users.erb
    # form requires that a `User` object is passed into the form
    #
    # @return [User]
    def blank_user_for_create_action_form
      @blank_user ||= User.new(
        provider_credentials: [GitHubProviderCredential.new]
      )
    end

    #####################################################
    # @!group Params: View parameters required
    #####################################################

    # @return [Set[Symbol]]
    def post_parameter_list_for_validation
      return Set.new(%w(id email))
    end
  end
end
