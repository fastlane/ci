require "set"

require_relative "../../shared/controller_base"
require_relative "../../services/services"

module FastlaneCI
  # Controller to help with onboarding a first-time user to fastlane.ci
  class OnboardingController < ControllerBase
    HOME = "/onboarding"

    # After a POST request where a status is set, clear the session[:method]
    # variable to avoid displaying the same message multiple times
    before do
      @progress = false

      if !session[:message].nil? && request.get?
        @message = session[:message]
        session[:message] = nil
      end
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
      @progress = true if has_ci_user?
      locals = { title: "Onboarding", variables: {} }
      erb(:ci_bot_account, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/initial_clone_user" do
      @progress = true if has_clone_user?
      locals = { title: "Onboarding", variables: {} }
      erb(:initial_clone_user, locals: locals, layout: FastlaneCI.default_layout)
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
    #    i.  write the encryption key to the `~/.fastlane/ci/.keys` file
    #    ii. load the new environment variables (implicitly)
    #
    # 3) If the encryption key is `nil`, display an error message
    post "#{HOME}/encryption_key" do
      if valid_params?(params, post_parameter_list_for_encryption_key_validation)
        Services.environment_variable_service.write_keys_file!(
          locals: format_params(
            params, post_parameter_list_for_encryption_key_validation
          )
        )

        session[:message] = <<~HTML
          ~/.fastlane/ci/keys file written with the configuration values:<br />
            FASTLANE_CI_ENCRYPTION_KEY=#{params[:encryption_key]}
        HTML
      else
        session[:message] = <<~HTML
          ERROR: ~/.fastlane/ci/keys file not written.
        HTML
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
        Services.environment_variable_service.write_keys_file!(
          locals: format_params(
            params, post_parameter_list_for_ci_bot_user_validation
          )
        )

        session[:message] = <<~HTML
          ~/.fastlane/ci/keys file written with the configuration values:<br />

          <ul>
            <li>FASTLANE_CI_USER=#{params[:ci_user_email]}</li>
            <li>FASTLANE_CI_PASSWORD=#{params[:ci_user_password]}</li>
          </ul>
        HTML
      else
        session[:message] = <<~HTML
          ERROR: ~/.fastlane/ci/keys file not written.
        HTML
      end

      redirect("#{HOME}/ci_bot_account")
    end

    # When the `/initial_clone_user` form is submitted:
    #
    # 1) Validate the data passed in
    #
    # 2) If the data is valid:
    #
    #    i.  write the environment variables file
    #    ii. load the new environment variables (implicitly)
    #
    # 3) If the data is not valid, display an error message
    post "#{HOME}/initial_clone_user" do
      if valid_params?(params, post_parameter_list_for_clone_user_validation)
        Services.environment_variable_service.write_keys_file!(
          locals: format_params(
            params, post_parameter_list_for_clone_user_validation
          )
        )

        session[:message] = <<~HTML
          ~/.fastlane/ci/keys file written with the configuration values:

          <ul>
            <li>FASTLANE_CI_INITIAL_CLONE_EMAIL='#{params[:clone_user_email]}'</li>
            <li>FASTLANE_CI_INITIAL_CLONE_API_TOKEN='#{params[:clone_user_api_token]}'</li>
          </ul>
        HTML
      else
        session[:message] = <<~HTML
          ERROR: ~/.fastlane/ci/keys file not written.
        HTML
      end

      redirect("#{HOME}/initial_clone_user")
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
        Services.environment_variable_service.write_keys_file!(
          locals: format_params(
            params, post_parameter_list_for_git_repo_validation
          )
        )
        Services.configuration_repository_service.create_private_remote_configuration_repo
        Services.onboarding_service.trigger_initial_ci_setup
        Launch.start_github_workers

        session[:message] = <<~HTML
          Remote repo #{params[:repo_url]} successfully created
        HTML
      else
        session[:message] = <<~HTML
          ERROR: Remote repository was not successfully created
        HTML
      end

      redirect("#{HOME}/git_repo")
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
    # @!group Helpers: View Helper Functions
    #####################################################

    # @return [Boolean]
    def has_encryption_key?
      not_nil_and_not_empty?(FastlaneCI.env.encryption_key)
    end

    # @return [Boolean]
    def has_ci_user?
      not_nil_and_not_empty?(FastlaneCI.env.ci_user_email) &&
        not_nil_and_not_empty?(FastlaneCI.env.ci_user_password)
    end

    # @return [Boolean]
    def has_clone_user?
      not_nil_and_not_empty?(FastlaneCI.env.initial_clone_email) &&
        not_nil_and_not_empty?(FastlaneCI.env.clone_user_api_token)
    end

    # @return [Boolean]
    def has_remote_github_repo?
      # Need the encryption key for the configuration_repository_service
      return false unless not_nil_and_not_empty?(FastlaneCI.env.encryption_key)

      not_nil_and_not_empty?(FastlaneCI.env.repo_url) &&
        Services.onboarding_service.correct_setup?
    end

    #####################################################
    # @!group Parameters: Parameter Validation Lists
    #####################################################

    # @return [Set[String]]
    def post_parameter_list_for_encryption_key_validation
      Set.new(%w(encryption_key))
    end

    # @return [Set[String]]
    def post_parameter_list_for_ci_bot_user_validation
      Set.new(%w(ci_user_email ci_user_password))
    end

    # @return [Set[String]]
    def post_parameter_list_for_clone_user_validation
      Set.new(%w(clone_user_email clone_user_api_token))
    end

    # @return [Set[String]]
    def post_parameter_list_for_git_repo_validation
      Set.new(%w(repo_url))
    end

    #####################################################
    # @!group Internals: Internal Helper Functions
    #####################################################

    # Returns `true` if a string is both non-nil and not empty
    #
    # @param  [String] value
    # @return [Boolean]
    def not_nil_and_not_empty?(value)
      !value.nil? && !value.empty?
    end
  end
end
