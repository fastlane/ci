require_relative "logging_module"

module FastlaneCI
  # A module to ensure that a user has the proper configuration setup
  module SetupChecker
    include FastlaneCI::Logging

    # Before each route, this function will check to see if the user is setup
    # correctly. Should the user not be setup correctly, they will be redirected
    # to the onboarding page `/onboarding`
    #
    # @param [Sinatra::Route] route
    def ensure_proper_setup(route = nil)
      route = "#{self::HOME}*" if route.nil?

      before(route) do
        if !route.start_with?("/onboarding") && !Services.onboarding_service.correct_setup?
          logger.debug("User is not yet onboarded. Directing them to `/onboarding`")
          redirect("/onboarding")
        elsif route.start_with?("/onboarding") && Services.onboarding_service.correct_setup?
          redirect("/")
        else
          logger.debug("User is onboarded, accessing #{route}")
        end
      end
    end
  end
end
