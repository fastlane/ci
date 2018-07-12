require_relative "api_controller"

module FastlaneCI
  # Controller for providing all setup APIs
  class SetupJSONController < APIController
    HOME = "/data/setup"

    get "#{HOME}/configured", authenticate: false do
      return json(Services.onboarding_service.correct_setup?)
    end

    post HOME.to_s, authenticate: false do
      # Before doing **anything** we have to make sure the server wasn't previously
      # set up already. To do so, we'll check for an existing dot files config
      if Services.onboarding_service.correct_setup?
        # Well, the set up is running, so somebody was trying to overwrite the
        # setup. Not something we'll tolerate
        json_error!(
          error_message: "fastlane.ci already set up, you can't overwrite the existing configuration",
          error_key: "Onboarding"
        )
      end

      # we set this as default so that we don't need duplicate code for error detection
      params["bot_account"] ||= {}

      encryption_key = params["encryption_key"]
      bot_token = params["bot_account"]["token"]
      bot_password = params["bot_account"]["password"] # TODO: What do we need this for
      config_repo = params["config_repo"].to_s
      initial_onboarding_token = params["initial_onboarding_token"]

      missing_parameters = {
        encryption_key: encryption_key,
        bot_token: bot_token,
        bot_password: bot_password,
        config_repo: config_repo,
        initial_onboarding_token: initial_onboarding_token
      }.find_all { |k, v| v.to_s.length == 0 }.to_h.keys

      if missing_parameters.count > 0
        json_error!(
          error_message: "Missing required parameters #{missing_parameters.join(', ')}",
          error_key: "Onboarding.Parameter.Missing"
        )
      end

      dot_keys_values = {}

      # Step: Validate & store the bot's GH API token
      validate_api_token_correct!(bot_token)
      dot_keys_values[:ci_user_api_token] = bot_token

      # Step: Validate & store the bot's password
      # TODO: We don't validate anything yet
      dot_keys_values[:ci_user_password] = bot_password

      # Step: Validate initial onboarding token
      validate_api_token_correct!(initial_onboarding_token)
      dot_keys_values[:initial_onboarding_user_api_token] = initial_onboarding_token

      # Step: Validate encryption key
      validate_encryption_key!(encryption_key)
      dot_keys_values[:encryption_key] = encryption_key

      # Step: Validate repo URL
      validate_repo_url!(config_repo)
      dot_keys_values[:repo_url] = config_repo

      # The `.write_keys_file!` resets all services we already have running
      # this is relevant when writing tests for this class
      Services.dot_keys_variable_service.write_keys_file!(
        locals: dot_keys_values
      )

      # After validating all the inputs, as well as storing all the inputs
      # using the `dot_keys_variable_service` we can finally launch all
      # the other services we need
      begin
        Services.configuration_repository_service.setup_private_configuration_repo

        # TODO: Right now this is a blocking HTTP call
        # as we clone the repo as part of it
        # We should replace this with a simple check if we have access
        # and clone async and have a check API to wait for the clone
        # to be finished
        Services.onboarding_service.clone_remote_repository_locally
      rescue StandardError => ex
        # Onboarding not successful, let's reset the dot files again
        Services.dot_keys_variable_service.write_keys_file!(locals: {
          ci_base_url: nil,
          encryption_key: nil,
          ci_user_password: nil,
          ci_user_api_token: nil,
          repo_url: nil,
          initial_onboarding_user_api_token: nil
        })

        logger.error(ex)

        # Return an error message to the user
        json_error!(
          error_message: "Failed to clone the ci-config repo, please make sure the bot has access to it",
          error_key: "Onboarding.ConfigRepo.NoAccess"
        )
      end
      Launch.start_github_workers

      return json({})
    end

    #####################################################
    # @!group Input validation
    #####################################################

    private

    def validate_api_token_correct!(api_token)
      if api_token.length != 40
        json_error!(
          error_message: "The GitHub token format is valid, they should be 40 characters long",
          error_key: "Onboarding.Token.Invalid"
        )
      end

      scope_validation_error = FastlaneCI::GitHubService.token_scope_validation_error(api_token)

      unless scope_validation_error.nil?
        scopes, required = scope_validation_error
        scopes_list_wording = scopes.count > 0 ? scopes.map { |scope| "\"#{scope}\"" }.join(",") : "empty"
        scopes_wording = scopes.count > 1 ? "scopes" : "scope"
        error_message = "Token should include \"#{required}\" scope, currently it's" \
                        " in #{scopes_list_wording} #{scopes_wording}."

        json_error!(
          error_message: error_message,
          error_key: "Onboarding.Token.MissingScope"
        )
      end
    end

    def validate_encryption_key!(encryption_key)
      if encryption_key.to_s.length < 5
        json_error!(
          error_message: "Encryption key not long enough, it must be at least 5 characters",
          error_key: "Onboarding.EncryptionKey.TooShort"
        )
      end
    end

    def validate_repo_url!(repo_url)
      # We only allow https:// based git repos for now
      unless repo_url.downcase.start_with?("https://")
        json_error!(
          error_message: "The config repo URL has to start with https://",
          error_key: "Onboarding.ConfigRepo.NoHTTPs"
        )
      end

      # We don't have to check if we have permission, as we'll try to
      # clone the repo as part of `Services.onboarding_service.clone_remote_repository_locally`
    end
  end
end
