require_relative "api_controller"

module FastlaneCI
  # Controller for providing all setup APIs
  class SetupJSONController < APIController
    HOME = "/data/setup"

    get "#{HOME}/configured_sections", authenticate: false do
      return json({
        encryption_key: !FastlaneCI.dot_keys.encryption_key.nil?,
        # Setting the OAuth keys without a provider type is not robust, we should
        # find a way to differentiate client ID/Secret by provider type (Ex. GitHub)
        oauth: !FastlaneCI.dot_keys.oauth_client_id.nil? && !FastlaneCI.dot_keys.oauth_client_secret.nil?,
        config_repo: !FastlaneCI.dot_keys.repo_url.nil?
      })
    end
  end
end
