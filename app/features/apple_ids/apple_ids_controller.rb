require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  # A CRUD controller to manage Apple ID credentials
  class AppleIDsController < AuthenticatedControllerBase
    HOME = "/apple_ids_erb"

    get HOME do
      locals = { title: "Apple IDs" }
      erb(:apple_ids, locals: locals, layout: FastlaneCI.default_layout)
    end

    # When the `/environment_variables/create` form is submitted:
    #
    # - creates a new ENV variables
    post "#{HOME}/create" do
      new_apple_id = nil
      if valid_params?(params, post_parameter_list_for_validation)
        new_apple_id = Services.apple_id_service.create_apple_id!(
          user: params[:user],
          password: params[:password],
          prefix: params[:prefix]
        )
      end

      if new_apple_id.nil?
        # Print out error message here, either parameters were invalid,
        # or key was already taken
        logger.error("Something went wrong")
      end

      redirect(HOME)
    end

    # More methods could be taken from EnvironmentVariablesController

    private

    #####################################################
    # @!group Data: View-specific data
    #####################################################

    # @return [Array[AppleID]]
    def apple_ids
      return Services.apple_id_service.apple_ids
    end

    #####################################################
    # @!group Params: View parameters required
    #####################################################

    # @return [Set[Symbol]]
    def post_parameter_list_for_validation
      # TODO: currently we don't make use of `prefix`
      return Set.new(%w(user password))
    end
  end
end
