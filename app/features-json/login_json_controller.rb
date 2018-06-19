require_relative "../services/user_service"
require_relative "api_controller"
require_relative "json_params"

module FastlaneCI
  # Controller responsible of handling the login process using JWT token.
  class LoginJSONController < APIController
    disable(:authentication)

    HOME = "/api/login"

    post HOME.to_s do
      user = Services.user_service.login(email: params[:email], password: params[:password])
      if user.nil?
        json_error!(
          error_message: "Invalid username or password",
          error_key: "Authentication.InvalidLogin",
          error_code: 401
        )
      end

      json({ token: token(user) })
    end

    private

    def token(user)
      JWT.encode(payload(user), settings.jwt_secret, settings.jwt_algo)
    end

    def payload(user)
      {
        # One month expire time is more than safe for now.
        exp: Time.now.to_i + (60 * 60 * 24 * 30),
        iat: Time.now.to_i,
        iss: "fastlane.ci",
        # We are only going to pass the user primary key to the client in order
        # to make sure that the calls being made to other services are made with
        # the correct relationship tree between objects being checked.
        user: user.id.to_s
      }
    end
  end
end
