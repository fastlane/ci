require "sinatra/base"
require "sinatra/reloader"
require "jwt"

require_relative "../services/services"
require_relative "json_params"

module FastlaneCI
  ##
  # APIController is designed for state-less API requests servicing the Angular front-end
  #
  # Requests are expected to be application/json.
  # The `params` method can be used to access the JSON body as if it were a hash
  #
  # Authentication is enabled by default. It can be disabled for the entire controller,
  # and individual endpoints can be give an authentication conditions.
  #
  # Usage
  # ===
  # Subclass the APIController for any controller that you expect JSON requests and responses.
  #
  # Settings
  # ===
  #
  # The following settings are provided to subclasses of APIController:
  #
  # * `authentication`- boolean value that makes every request check authentication before each action.
  #    Disable with: `disable :authentication`. Enabled by default.
  # * `authenticate_via` - which authentication scheme to use. `:jwt` by default.
  # * `jwt_secret` - The key to use in decoding JWT tokens.
  #
  # Per-route Authentication
  # ===
  # If you disable authentication for the whole controller, you can enable it on a per-route basis using
  # a route condition like this:
  #
  #   get "/private", authenticate: :jwt do
  #     json({message: "secret"})
  #   end
  #
  # You may also selectively disable on a per-route basis by passing `authenticate: false` to the route:
  #
  #   get "/public", authenticate: false do
  #     json({message: "public"})
  #   end
  #
  # This will always bypass any authentication setting.
  #
  # User authentication
  # ===
  # This controller also provides a few helper methods that return information about the current user
  # * `user_id` - the user id encoded in the jwt.
  # * `current_user` - the user model fetched from the data service, or nil if it cannot be found.
  # * `user_logged_in?` - boolean whether the user is found.
  #
  class APIController < Sinatra::Base
    include JSONParams
    include Logging

    configure(:development) do
      register Sinatra::Reloader
    end

    configure(:production, :development) do
      enable(:logging)
    end

    # to disabled authentication for the entire controller use:
    # disable(:authentication)
    set(:authentication, true)

    # the default authentication scheme. We only support `:jwt` at this time.
    set(:authenticate_via, :jwt)

    # the condition can be added to any route
    set(:authenticate) do |auth_type|
      condition { authenticate!(via: auth_type) }
    end

    # the JWT secret uses the fastlane encryption key
    set(:jwt_secret, FastlaneCI.dot_keys.encryption_key)
    set(:jwt_algo, "HS256")

    ##
    # override the route by injecting the `authenticate` condition.
    # use this instead of adding a `before` block which are terrible.
    def self.route(verb, path, options = {}, &block)
      if settings.authentication? && !options.key?(:authenticate)
        options[:authenticate] = settings.authenticate_via
      end

      super
    end

    helpers do
      # Decode the JWT or halt.
      def jwt
        authorization = request.env["HTTP_AUTHORIZATION"]
        bearer_token = authorization && authorization.slice(7..-1) # strip off the `Bearer `

        # give the option to pass the bearer token as a query param.
        # this is used when making websocket connections which do not allow us to set http headers
        bearer_token ||= request.params["bearer_token"]

        payload, _header = JWT.decode(
          bearer_token,
          settings.jwt_secret,
          true, # Validate Issuer?
          { verify_iss: true, verify_iat: true, algorithm: "HS256", iss: "fastlane.ci" } # Options
        )

        return payload
      rescue JWT::InvalidIssuerError
        json_error!(
          error_message: "The token does not have a valid issuer",
          error_key: "Authentication.Token.InvalidIssuer",
          error_code: 403
        )
      rescue JWT::InvalidIatError
        json_error!(
          error_message: "The token does not have a valid 'issued at' time",
          error_key: "Authentication.Token.MissingIssuedTime",
          error_code: 403
        )
      rescue JWT::ExpiredSignature
        json_error!(
          error_message: "The token has expired",
          error_key: "Authentication.Token.Expired",
          error_code: 401
        )
      rescue JWT::DecodeError
        json_error!(
          error_message: "A token must be passed",
          error_key: "Authentication.Token.Missing",
          error_code: 401
        )
      end

      # dispatch to the different authentication schemes available.
      def authenticate!(via:)
        logger.info("Authenticating via #{via}")

        case via
        when :jwt
          return jwt
        when false
          logger.info("Skipping authentication.")
        else
          raise "`#{via}` is an un-supported authentication scheme."
        end
      end

      # if more `authenticate_via`` options get added, change this method
      def user_id
        payload = authenticate!(via: :jwt)
        return payload["user"]
      end

      # provides access to the User model. Memoize @current_user so we don't do unnecessary i/o.
      def current_user
        @current_user ||= FastlaneCI::Services.user_service.find_user(id: user_id)
        unless @current_user
          json_error!(
            error_message: "User not found",
            error_key: "Authentication.UserNotFound",
            error_code: 404
          )
        end

        return @current_user
      end

      def user_logged_in?
        current_user != nil
      end

      # @param error_message [String]: A human readable error message
      # @param error_key [String]: a machine readable error code, nested with .
      #                            check out docs/API.md for more information
      # @param error_message [String]: optional, HTTP error code
      def json_error!(error_message:, error_key:, error_code: 400)
        logger.info("Error #{error_key} (#{error_code})")

        # Better have "Unknown" than an empty string or `nil`
        error_key = "Unknown" if error_key.to_s.length == 0

        # Set the HTTP status for Sinatra
        status(error_code)

        # Use `halt` to immediately return the error
        # to the client
        halt(error_code, json({
          message: error_message,
          key: error_key
        }))
      end

      def current_user_provider_credential
        provider_credential = current_user.provider_credential
        unless provider_credential
          json_error!(
            error_message: "Provider Credential not found",
            error_key: "Authentication.ProviderCredentialNotFound",
            error_code: 404
          )
        end

        return provider_credential
      end

      def current_user_config_service
        FastlaneCI::ConfigService.new(ci_user: current_user)
      end
    end
  end
end
