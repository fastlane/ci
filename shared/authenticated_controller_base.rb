require_relative "authentication_request_checker"
require_relative "controller_base"

module FastlaneCI
  #
  # A user is required to be logged in to access any routes on this controller
  #
  class AuthenticatedControllerBase < ControllerBase
    register AuthenticatedRequestChecker

    def initialize(app)
      super(app)

      self.class.ensure_logged_in
    end
  end
end
