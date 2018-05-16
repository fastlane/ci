require_relative "../../services/dot_keys_variable_service"

require "jwt"

module FastlaneCI
  # API Middleware responsible of authenticate all the requests that uses it.
  class JwtAuth
    def initialize(app, encryption_key=nil)
      @app = app
      @encryption_key = encryption_key || FastlaneCI.dot_keys.encryption_key
    end

    def call(env)
      options = { verify_iss: true, verify_iat: true, algorithm: "HS256", iss: "fastlane.ci" }
      bearer = env.fetch("HTTP_AUTHORIZATION", "").slice(7..-1)
      payload = JWT.decode(bearer, @encryption_key, true, options)

      raise "Missing user ID in payload." unless payload["user"]
      env[:user] = payload["user"]

      @app.call(env)
    rescue JWT::InvalidIssuerError
      [403, { "Content-Type" => "text/plain" }, ["The token does not have a valid issuer."]]
    rescue JWT::InvalidIatError
      [403, { "Content-Type" => "text/plain" }, ['The token does not have a valid "issued at" time.']]
    rescue JWT::ExpiredSignature
      [401, { "Content-Type" => "text/plain" }, ["The token has expired."]]
    rescue JWT::DecodeError
      [401, { "Content-Type" => "text/plain" }, ["A token must be passed."]]
    rescue StandardError => ex
      [500, { "Content-Type" => "text/plain" }, [ex.to_s]]
    end
  end
end
