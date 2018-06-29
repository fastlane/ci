require_relative "api_controller"

module FastlaneCI
  # Controller for providing all setup APIs
  class SetupJSONController < APIController
    HOME = "/data/setup"

    get "#{HOME}/configured", authenticate: false do
      return json(Services.onboarding_service.correct_setup?)
    end

    get "#{HOME}/user_details" do
      code_hosting_service = current_user_config_service.code_hosting_service(
        provider_credential: Services.provider_credential
      )

      # For now we only support GitHub, it will be easy to support more in the future
      json(
        github: {
          username: code_hosting_service.username,
          email: code_hosting_service.email
        }
      )
    end
  end
end
