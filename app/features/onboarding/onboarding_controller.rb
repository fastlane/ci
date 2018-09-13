require "set"

require_relative "../../shared/controller_base"
require_relative "../../services/services"

module FastlaneCI
  # Controller to help with onboarding a first-time user to fastlane.ci
  class OnboardingController < ControllerBase
    HOME = "/onboarding_erb"

    # After a POST request where a status is set, clear the session[:method]
    # variable to avoid displaying the same message multiple times
    before do
      @progress = false
    end

    get HOME do
      locals = { title: "Onboarding", variables: {} }
      erb(:index, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/encryption_key" do
      @progress = true if has_encryption_key?
      locals = { title: "Onboarding", variables: {} }
      erb(:encryption_key, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/ci_bot_account" do
      @progress = true if has_ci_user_password? && has_ci_user_api_token?
      locals = { title: "Onboarding", variables: {} }
      erb(:ci_bot_account, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/initial_onboarding_user" do
      @progress = true if has_initial_onboarding_user_api_token?
      locals = { title: "Onboarding", variables: {} }
      erb(:initial_onboarding_user, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/git_repo" do
      @progress = true if has_remote_github_repo?
      locals = { title: "Onboarding", variables: {} }
      erb(:git_repo, locals: locals, layout: FastlaneCI.default_layout)
    end

    # When the `/encryption_key` form is submitted:
    #
    # 1) Validate the encryption key passed in is not `nil`
    #
    # 2) If the encryption key is not `nil`:
    #
    #    i.  write the encryption key to the CI keys file (FastlaneCI::DotKeysVariableService#keys_file_path)
    #    ii. load the new environment variables (implicitly)
    #
    # 3) If the encryption key is `nil`, display an error message
    post "#{HOME}/encryption_key" do
      if valid_params?(params, post_parameter_list_for_encryption_key_validation)
        Services.dot_keys_variable_service.write_keys_file!(
          locals: format_params(
            params, post_parameter_list_for_encryption_key_validation
          )
        )

        logger.debug("#{Services.dot_keys_variable_service.keys_file_path_relative_to_home} file written.")
      else
        logger.debug("#{Services.dot_keys_variable_service.keys_file_path_relative_to_home} file not written.")
      end

      redirect("#{HOME}/encryption_key")
    end

    # When the `/ci_bot_account` form is submitted:
    #
    # 1) Validate the data passed in
    #
    # 2) If the data is valid:
    #
    #    i.  write the environment variables file
    #    ii. load the new environment variables (implicitly)
    #
    # 3) If the data is not valid, display an error message
    post "#{HOME}/ci_bot_account" do
      if valid_params?(params, post_parameter_list_for_ci_bot_user_validation)
        validate_api_token_correct(params[:ci_user_api_token].strip, "ci_bot_account")

        Services.dot_keys_variable_service.write_keys_file!(
          locals: format_params(
            params, post_parameter_list_for_ci_bot_user_validation
          )
        )

        logger.debug("#{Services.dot_keys_variable_service.keys_file_path_relative_to_home}</code> file written.")
      else
        logger.debug("#{Services.dot_keys_variable_service.keys_file_path_relative_to_home} file not written.")
      end

      redirect("#{HOME}/ci_bot_account")
    end

    # When the `/initial_onboarding_user` form is submitted:
    #
    # 1) Validate the data passed in
    #
    # 2) If the data is valid:
    #
    #    i.  write the environment variables file
    #    ii. load the new environment variables (implicitly)
    #
    # 3) If the data is not valid, display an error message
    post "#{HOME}/initial_onboarding_user" do
      if valid_params?(params, post_parameter_list_for_onboarding_user_validation)
        api_token = params[:initial_onboarding_user_api_token].strip
        if api_token.length != 40
          error_message = "Invalid API token, please ensure you entered an API token and not a password"
          logger.error(error_message)
          logger.error("API tokens are generated by GitHub and are 40 characters long")

          redirect("#{HOME}/initial_onboarding_user")
        end

        scope_validation_error = FastlaneCI::GitHubService.token_scope_validation_error(
          params[:initial_onboarding_user_api_token]
        )

        if scope_validation_error.nil?
          validate_api_token_correct(params[:initial_onboarding_user_api_token].strip, "initial_onboarding_user")

          Services.dot_keys_variable_service.write_keys_file!(
            locals: format_params(
              params, post_parameter_list_for_onboarding_user_validation
            )
          )
        else
          scopes, required = scope_validation_error
          scopes_list_wording = scopes.count > 0 ? scopes.map { |scope| "\"#{scope}\"" }.join(",") : "empty"
          scopes_wording = scopes.count > 1 ? "scopes" : "scope"
          # rubocop:disable Metrics/LineLength
          error_message = "Token should be in \"#{required}\" scope, currently it's in #{scopes_list_wording} #{scopes_wording}."
          # rubocop:enable Metrics/LineLength
          logger.error(error_message)
        end
      end

      redirect("#{HOME}/initial_onboarding_user")
    end

    # When the `/git_repo` form is submitted:
    #
    # 1) Creates and clones a private configuration repository:
    #
    #    i.   create the private configuration git repo remotely (if it doesn't
    #         already exist)
    #    ii.  clone the configuration repo
    #    iii. run github workers
    #
    # 2) Redirect back to `/configuration`
    post "#{HOME}/git_repo" do
      if valid_params?(params, post_parameter_list_for_git_repo_validation)
        Services.dot_keys_variable_service.write_keys_file!(
          locals: format_params(
            params, post_parameter_list_for_git_repo_validation
          )
        )
        Services.configuration_repository_service.setup_private_configuration_repo
        Services.onboarding_service.clone_remote_repository_locally
        Launch.start_github_workers
      else
        logger.debug("Remote repository was not successfully created")
      end

      redirect("#{HOME}/git_repo")
    end

    private

    #####################################################
    # @!group Redirect Helpers
    #####################################################

    def validate_api_token_correct(api_token, route)
      if api_token.length != 40
        error_message = "Invalid API token, please ensure you entered an API token and not a password"
        logger.error(error_message)
        logger.error("API tokens are generated by GitHub and are 40 characters long")

        redirect("#{HOME}/#{endpoint}")
      end
    end

    #####################################################
    # @!group Data: View-specific data
    #####################################################

    # @return [Hash]
    def keys
      return FastlaneCI.dot_keys.all
    end

    #####################################################
    # @!group Helpers: View Helper Functions
    #####################################################

    # @return [Boolean]
    def has_encryption_key?
      return not_nil_and_not_empty?(FastlaneCI.dot_keys.encryption_key)
    end

    # @return [Boolean]
    def has_ci_user_password?
      return not_nil_and_not_empty?(FastlaneCI.dot_keys.ci_user_password)
    end

    # @return [Boolean]
    def has_ci_user_api_token?
      return not_nil_and_not_empty?(FastlaneCI.dot_keys.ci_user_api_token)
    end

    # @return [Boolean]
    def has_initial_onboarding_user_api_token?
      return not_nil_and_not_empty?(FastlaneCI.dot_keys.initial_onboarding_user_api_token)
    end

    # @return [Boolean]
    def has_remote_github_repo?
      if not_nil_and_not_empty?(FastlaneCI.dot_keys.encryption_key)
        return not_nil_and_not_empty?(FastlaneCI.dot_keys.repo_url) &&
               Services.onboarding_service.correct_setup?
      else
        # Need the encryption key for the configuration_repository_service
        return false
      end
    end

    #####################################################
    # @!group Parameters: Parameter Validation Lists
    #####################################################

    # @return [Set[String]]
    def post_parameter_list_for_encryption_key_validation
      return Set.new(%w(encryption_key))
    end

    # @return [Set[String]]
    def post_parameter_list_for_ci_bot_user_validation
      return Set.new(%w(ci_user_password ci_user_api_token))
    end

    # @return [Set[String]]
    def post_parameter_list_for_onboarding_user_validation
      return Set.new(%w(initial_onboarding_user_api_token))
    end

    # @return [Set[String]]
    def post_parameter_list_for_git_repo_validation
      return Set.new(%w(repo_url))
    end

    #####################################################
    # @!group Internals: Internal Helper Functions
    #####################################################

    # Returns `true` if a string is both non-nil and not empty
    #
    # @param  [String] value
    # @return [Boolean]
    def not_nil_and_not_empty?(value)
      return !value.nil? && !value.empty?
    end
  end
end
