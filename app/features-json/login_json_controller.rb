require_relative "../shared/controller_base"
require_relative "../services/user_service"
require_relative "../services/dot_keys_variable_service"

require "jwt"
require "json"

module FastlaneCI
  # Controller responsible of handling the login process using JWT token.
  class LoginJSONController < ControllerBase
    HOME = "/login"

    post HOME.to_s do
      # Allow this endpoint to be requested with { Content-Type: application/json }
      payload = params
      payload = JSON.parse(request.body.read).symbolize_keys unless params[:path]
      email = payload[:email]
      password = payload[:password]
      user = Services.user_service.login(email: email, password: password)
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
        exp: Time.now.to_i + 60 * 60,
        iat: Time.now.to_i,
        # TODO: We shall figure out how to identify the source of the authentication
        # (i.e., third-party webapps, our angular app, etc.)
        iss: "fastlane.ci",
        scopes: ["default"],
        user: user.provider_credentials.map! do |credential|
          credential.to_object_dictionary(ignore_instance_variables: [:@ci_user])
        end
      }
    end
  end
end
