require_relative "logging_module"
require_relative "models/provider_credential"

module FastlaneCI
  # by registering this module in your controller you can call `ensure_logged_in` for any route
  # you want. Alternatively, you can subclass AuthenticatedControllerBase and every route that
  # originates from `self::HOME` in that class will be registered
  module AuthenticatedRequestChecker
    include FastlaneCI::Logging

    def ensure_logged_in(route = nil)
      if route.nil?
        if defined?(self::HOME)
          route = "#{self::HOME}*"
        else
          message = "\nYou must define a const called `HOME` on #{self} or you must pass the routes you intend to protect to `ensure_logged_in()`\n"
          raise message
        end
      end
      logger.debug("requiring logged-in user for access to `#{route}`")

      before(route) do
        raise "ensure_logged_in requires a `route`" if route.nil?

        logger.debug("checking if user is logged in... ")

        # TODO: we don't want to directly access `session` here, abstract out
        # We could use
        # ```
        # FastlaneCI::GitHubSource.source_from_provider_credential(provider).session_valid?
        # ```
        # however this would send a request every single time
        # Let's revisit later on
        user = session[:user]
        if user.nil?
          logger.debug("No fastlane.ci account found, redirecting to login")
          redirect("/login/ci_login")
        end

        if user.provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]).nil?
          logger.debug("No provider credentials found, redirecting to GitHub provider page")
          redirect("/login")
        else
          logger.debug("User is authenticated, accessing #{route}")
        end
      end
    end
  end
end
