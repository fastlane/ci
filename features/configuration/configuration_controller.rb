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
    HOME = "/configuration"

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
    #    ii. load the new environment variables
    #
    # 3) If the data is not valid, display an error message
    post "#{HOME}/keys" do
      if valid_params?(params, post_parameter_list_for_validation)
        Services.environment_variable_service.write_keys_file!(locals: params)
        Services.environment_variable_service.reload_dot_env!
        variables = { status: STATUS[:success], message: "~/.fastlane/ci/keys file written." }
      else
        variables = { status: STATUS[:error], message: "~/.fastlane/ci/keys file NOT written." }
      end

      locals = { title: "Configuration", variables: variables }
      erb(:index, locals: locals, layout: FastlaneCI.default_layout)
    end

    # When the `/git_repo` form is submitted:
    #
    # 1) Creates and clones a private configuration repository:
    #
    #    i.   create the private configuration git repo remotely
    #    ii.  reset the services that rely on environment variables
    #    iii. clone the configuration repo
    #    iv.  run github workers
    #
    # 2) Redirect back to `/configuration`
    post "#{HOME}/git_repo" do
      if keys.none?(&:nil?)
        Services.configuration_repository_service.create_private_remote_configuration_repo
        Services.reset_services!
        Launch.trigger_initial_ci_setup
        Launch.run_github_workers
        variables = { status: STATUS[:success], message: "Remote repo successfully created" }
      else
        variables = { status: STATUS[:error], message: "Remote repo NOT successfully created" }
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
      FastlaneCI.env.all
    end

    #####################################################
    # @!group Locals: View-specific locals
    #####################################################

    # @return [Set[String]]
    def post_parameter_list_for_validation
      Set.new(
        %w(encryption_key ci_user_email ci_user_api_token repo_url
           clone_user_email clone_user_api_token)
      )
    end

    #####################################################
    # @!group Helpers: Random helper functions
    #####################################################

    # @return [Boolean]
    def first_time_user?
      !Services.configuration_repository_service.configuration_repository_exists?
    end
  end
end
