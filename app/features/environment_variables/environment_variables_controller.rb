require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  # A CRUD controller to manage environment variables
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
      new_environment_variable = nil
      if valid_params?(params, post_parameter_list_for_validation)
        new_environment_variable = Services.environment_variable_service.create_environment_variable!(
          key: params[:key],
          value: params[:value]
        )
      end

      if new_environment_variable.nil?
        # Print out error message here, either parameters were invalid,
        # or key was already taken
        logger.error("Something went wrong")
      end

      redirect(HOME)
    end

    # Updates an environment variable
    post "#{HOME}/update" do
      if valid_params?(params, post_parameter_list_for_validation)
        environment_variable = EnvironmentVariable.new(
          key: params[:key],
          value: params[:value]
        )

        Services.environment_variable_service.update_environment_variable!(
          environment_variable: environment_variable
        )
      end

      redirect(HOME)
    end

    # Deletes an environment variable existing in the configuration repository `environment_variables.json`
    post "#{HOME}/delete/*" do |environment_variable_key|
      Services.environment_variable_service.delete_environment_variable!(
        environment_variable_key: environment_variable_key
      )

      redirect(HOME)
    end

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
