require_relative "../../shared/controller_base"
require_relative "../../services/user_service"
require_relative "../../services/dot_keys_variable_service"


require "jwt"
require "json"

module FastlaneCI
  class LoginJSONController < ControllerBase
    HOME = "/login"

    post HOME.to_s do
      email = params[:email]
      password = params[:password]
      user = Services.user_service.login(email: email, password: password)
      if user.nil?
        halt(401)
      else
        content_type :json
        { token: token(user) }.to_json
      end
    end

    private

    def token(user)
      JWT.encode(payload(user), FastlaneCI.dot_keys.encryption_key, 'HS256')
    end

    def payload(user)
      {
        exp: Time.now.to_i + 60 * 60,
        iat: Time.now.to_i,
        iss: "fastlane.ci", # TODO: We shall figure out how to identify the source of the authentication (i.e., third-party webapps, our angular app, etc.) 
        scopes: ["default"],
        user: user.to_json
      }
  end
end