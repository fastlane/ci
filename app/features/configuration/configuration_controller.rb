require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  #
  # A CRUD controller to manage configuration data for FastlaneCI. Walks the
  # user through configuration should they not have the proper metadata required
  # to run the server
  #
  class ConfigurationController < AuthenticatedControllerBase
    HOME = "/configuration_erb"

    get HOME do
      locals = { title: "Configuration", variables: {} }
      erb(:index, locals: locals, layout: FastlaneCI.default_layout)
    end

    # When the `/keys` form is submitted:
    #
    # 1) Validate the data passed in
    #
    # 2) If the data is valid:
    #
    #    i.  write the environment variables file
    #    ii. load the new environment variables (implicitly upon file write)
    #
    # 3) If the data is not valid, display an error message
    post "#{HOME}/keys" do
      if valid_params?(params, post_parameter_list_for_validation)
        Services.environment_variable_service.write_keys_file!(locals: params)
        variables = { status: STATUS[:success], message: "#{Services.environment_variable_service.keys_file_path_relative_to_home} file written." }
      else
        variables = { status: STATUS[:error], message: "#{Services.environment_variable_service.keys_file_path_relative_to_home} file NOT written." }
      end

      locals = { title: "Configuration", variables: variables }
      erb(:index, locals: locals, layout: FastlaneCI.default_layout)
    end

    private

    #####################################################
    # @!group Data: View-specific data
    #####################################################

    # @return [Hash]
    def keys
      return FastlaneCI.env.all
    end

    #####################################################
    # @!group Locals: View-specific locals
    #####################################################

    # @return [Set[String]]
    def post_parameter_list_for_validation
      return Set.new(
        %w(encryption_key ci_user_email ci_user_password repo_url
           clone_user_email clone_user_api_token)
      )
    end
  end
end
