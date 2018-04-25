require_relative "../services/dot_keys_variable_service"

require "jwt"

module FastlaneCI
  class JwtAuth
    def initialize(app)
      @app = app
    end

    def call(env)
      options = { algorithm: "HS256", iss: "fastlane.ci" }
      bearer = env.fetch("HTTP_AUTHORIZATION", "").slice(7..-1)
      payload, header = JWT.decode(bearer, FastlaneCI.dot_keys.encryption_key, true, options)

      env[:scopes] = payload["scopes"]
      env[:user] = payload["user"]

      @app.call(env)
    rescue JWT::DecodeError
      [401, { "Content-Type" => "text/plain" }, ["A token must be passed."]]
    rescue JWT::ExpiredSignature
      [403, { "Content-Type" => "text/plain" }, ["The token has expired."]]
    rescue JWT::InvalidIssuerError
      [403, { "Content-Type" => "text/plain" }, ["The token does not have a valid issuer."]]
    rescue JWT::InvalidIatError
      [403, { "Content-Type" => "text/plain" }, ['The token does not have a valid "issued at" time.']]
    end
  end
end
