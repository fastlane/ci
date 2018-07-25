require_relative "api_controller"

module FastlaneCI
  # Controller for providing all setup APIs
  class SetupJSONController < APIController
    HOME = "/data/setup"

    get "#{HOME}/configured_sections", authenticate: false do
      # Setting the OAuth keys without a provider type is not robust, we should
      # find a way to differentiate client ID/Secret by provider type (Ex. GitHub)
      is_oauth_configured = !FastlaneCI.dot_keys.oauth_client_id.nil? && !FastlaneCI.dot_keys.oauth_client_secret.nil?
      return json({
        encryption_key: !FastlaneCI.dot_keys.encryption_key.nil?,
        oauth: is_oauth_configured,
        config_repo: is_oauth_configured && !FastlaneCI.dot_keys.repo_url.nil?
      })
    end

    post "#{HOME}/encryption_key", authenticate: false do
      key = params["encryption_key"]

      if key.nil?
        json_error!(
          error_message: "Must provide encryption key",
          error_key: "EncryptionKey.Missing",
          error_code: 400
        )
      end

      unless FastlaneCI.dot_keys.encryption_key.nil?
        json_error!(
          error_message: "The encryption key has already been set",
          error_key: "EncryptionKey.AlreadyExists",
          error_code: 403
        )
      end

      Services.dot_keys_variable_service.write_keys_file!(
        locals: {
          encryption_key: key
        }
      )
    end

    post "#{HOME}/oauth", authenticate: false do
      client_id = params["client_id"].to_s
      client_secret = params["client_secret"].to_s

      if client_id.nil? || client_secret.nil?
        json_error!(
          error_message: "Must provide both the OAuth client ID and client secret",
          error_key: "OAuth.Missing",
          error_code: 400
        )
      end

      if !FastlaneCI.dot_keys.oauth_client_id.nil? && !FastlaneCI.dot_keys.oauth_client_secret.nil?
        json_error!(
          error_message: "The OAuth client has already been set",
          error_key: "OAuth.AlreadyExists",
          error_code: 403
        )
      end

      Services.dot_keys_variable_service.write_keys_file!(
        locals: {
          oauth_client_id: client_id,
          oauth_client_secret: client_secret
        }
      )
    end
  end
end
