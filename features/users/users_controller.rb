require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  # A CRUD controller to manage users
  class UsersController < AuthenticatedControllerBase
    HOME = "/users"

    # After a POST request where a status is set, clear the session[:method]
    # variable to avoid displaying the same message multiple times
    before do
      if !session[:message].nil? && request.get?
        @message = session[:message]
        session[:message] = nil
      end
    end

    get HOME do
      locals = { title: "Users" }
      erb(:users, locals: locals, layout: FastlaneCI.default_layout)
    end

    # When the `/users/create` form is submitted:
    #
    # - creates a user if the locals are valid
    post "#{HOME}/create" do
      session[:message] = "ERROR: User not created."

      if valid_params?(params, post_parameter_list_for_create)
        new_user = Services.user_service.create_user!(
          email: params[:email],
          password: params[:password]
        )
        session[:message] = "User #{params[:email]} created." if new_user
      end

      redirect(HOME)
    end

    # Updates a user existing in the configuration repository `users.json`
    # TODO: fix
    post "#{HOME}/update" do
      session[:message] = "ERROR: User not updated."

      if valid_params?(params, post_parameter_list_for_update)
        new_user = User.new(
          id: params[:id],
          email: params[:email],
          password: params[:password]
        )

        updated_user = Services.user_service.update_user!(new_user)
        session[:message] = "User #{params[:email]} updated." if updated_user
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
        id: "",
        provider_credentials: [GitHubProviderCredential.new(id: "")]
      )
    end

    #####################################################
    # @!group Params: View parameters required
    #####################################################

    # @return [Set[Symbol]]
    def post_parameter_list_for_create
      return Set.new(%w(email password))
    end

    # @return [Set[Symbol]]
    def post_parameter_list_for_update
      return Set.new(%w(id email))
    end
  end
end
