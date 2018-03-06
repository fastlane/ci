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
      status =
        if valid_params?(params, keys_params)
          Services.environment_variable_service.write_keys_file!(locals: params)
          Services.environment_variable_service.reload_dot_env!
          STATUS[:success]
        else
          STATUS[:error]
        end

      locals = { title: "Configuration", variables: { status: status } }
      erb(:index, locals: locals, layout: FastlaneCI.default_layout)
    end

    # When the `/git_repo` form is submitted:
    #
    # 1) Creates and clones a private configuration repository:
    #
    #    i.  create the private configuration git repo remotely
    #    ii. clone the configuration repo
    #
    # 2) Redirect back to `/configuration`
    post "#{HOME}/git_repo" do
      status =
        if keys.none?(&:nil?)
          Services.github_service.create_private_remote_configuration_repo
          Services.config_service.trigger_initial_ci_setup
          STATUS[:success]
        else
          STATUS[:error]
        end

      locals = { title: "Configuration", variables: { status: status } }
      erb(:index, locals: locals, layout: FastlaneCI.default_layout)
    end

    private

    #####################################################
    # @!group Data: View-specific data
    #####################################################

    # @return [Hash]
    def keys
      {
        encryption_key: ENV["FASTLANE_CI_ENCRYPTION_KEY"],
        ci_user_email: ENV["FASTLANE_CI_USER"],
        ci_user_api_token: ENV["FASTLANE_CI_PASSWORD"],
        repo_url: ENV["FASTLANE_CI_REPO_URL"],
        clone_user_email: ENV["FASTLANE_CI_INITIAL_CLONE_EMAIL"],
        clone_user_api_token: ENV["FASTLANE_CI_INITIAL_CLONE_API_TOKEN"]
      }
    end

    #####################################################
    # @!group Locals: View-specific locals
    #####################################################

    # @return [Set[String]]
    def keys_params
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
      Launch.first_time_user?
    end
  end
end
