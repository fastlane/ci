require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  # A CRUD controller to manage users
  class UsersController < AuthenticatedControllerBase
    HOME = "/users"

    get HOME do
      locals = { title: "Users" }
      erb(:users, locals: locals, layout: FastlaneCI.default_layout)
    end

    # When the `/users/create` form is submitted:
    #
    # - creates a user if the locals are valid
    post "#{HOME}/create" do
      if valid_params?(params, users_params)
        Services.user_service.create_user!(
          id: params[:id],
          email: params[:email],
          password: params[:password]
        )
      end

      redirect HOME
    end

    # Updates a user existing in the configuration repository `users.json`
    post "#{HOME}/update" do
      if valid_params?(params, users_params)
        new_user = User.new(
          id: params[:id],
          email: params[:email],
          password: params[:password]
        )

        Services.user_service.update_user!(new_user)
      end

      redirect HOME
    end

    private

    #####################################################
    # @!group Data: View-specific data
    #####################################################

    # @return [Array[User]]
    def users
      Services.user_service.user_data_source.users
    end

    # Empty user object for new user form
    #
    # @return [User]
    def new_user
      @new_user ||= User.new(provider_credentials: [GitHubProviderCredential.new])
    end

    # Empty provider credential
    #
    # @return [GitHubProviderCredential]
    def new_credential
      @new_credential ||= GitHubProviderCredential.new
    end

    #####################################################
    # @!group Params: View parameters required
    #####################################################

    # @return [Set[Symbol]]
    def users_params
      Set.new(%w(id email password_hash))
    end
  end
end
