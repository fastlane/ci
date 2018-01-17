require_relative "logging_module"

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
        # FastlaneCI::GitHubSource.source_from_session(session).session_valid?
        # ```
        # however this would send a request every single time
        # Let's revisit later on
        if session["GITHUB_SESSION_API_TOKEN"].to_s.length == 0
          logger.debug("No valid auth token found, redirecting to login")
          redirect("/login")
        else
          logger.debug("Yes, user got access to #{route}")
        end
      end
    end
  end
end
