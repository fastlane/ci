require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  # A CRUD controller to manage users
  class EnvironmentVariablesController < AuthenticatedControllerBase
    HOME = "/environment_variables_erb"

    get HOME do
      locals = { title: "Environment Variables" }
      erb(:environment_variables, locals: locals, layout: FastlaneCI.default_layout)
    end

    # When the `/environment_variables/create` form is submitted:
    #
    # - creates a new ENV variables
    post "#{HOME}/create" do
      if valid_params?(params, post_parameter_list_for_validation)
        Services.environment_variable_service.create_environment_variable!(
          key: params[:key],
          value: params[:value]
        )
      end

      redirect(HOME)
    end

    # # Updates a user existing in the configuration repository `users.json`
    # post "#{HOME}/update" do
    #   if valid_params?(params, post_parameter_list_for_validation)
    #     new_user = User.new(
    #       id: params[:id],
    #       email: params[:email]
    #     )

    #     Services.user_service.update_user!(new_user)
    #   end

    #   redirect(HOME)
    # end

    # # Deletes a user existing in the configuration repository `users.json`
    # post "#{HOME}/delete/*" do |user_id|
    #   user = Services.user_service.find_user(id: user_id)

    #   if !user.nil?
    #     Services.user_service.delete_user!(user: user)
    #   else
    #     logger.debug("User not deleted, since user with `id` #{user_id} does not exist.")
    #   end

    #   redirect(back)
    # end

    private

    #####################################################
    # @!group Data: View-specific data
    #####################################################

    # @return [Array[EnvironmentVariable]]
    def environment_variables
      return Services.environment_variable_service.environment_variables
    end

    #####################################################
    # @!group Params: View parameters required
    #####################################################

    # @return [Set[Symbol]]
    def post_parameter_list_for_validation
      return Set.new(%w(key value))
    end
  end
end
