require_relative "../shared/controller_base"
require_relative "../services/user_service"
require_relative "../services/dot_keys_variable_service"
require_relative "json_params"

require "jwt"
require "json"

module FastlaneCI
  # Controller responsible of handling the login process using JWT token.
  class LoginJSONController < ControllerBase
    include JSONParams

    HOME = "/api/login"

    post HOME.to_s do
      # Allow this endpoint to be requested with { Content-Type: application/json }
      user = Services.user_service.login(email: params[:email], password: params[:password])
      if user.nil?
        halt(401)
      else
        content_type(:json)
        { token: token(user) }.to_json
      end
    end

    private

    def token(user)
      JWT.encode(payload(user), FastlaneCI.dot_keys.encryption_key, "HS256")
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
