require_relative "api_controller"

module FastlaneCI
  # Controller for providing all setup APIs
  class SetupJSONController < APIController
    HOME = "/data/setup"

    get "#{HOME}/configured", authenticate: false do
      return json(Services.onboarding_service.correct_setup?)
    end
  end
end
