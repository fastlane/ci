require_relative "../services/user_service"
require_relative "api_controller"
require_relative "json_params"
require "faraday"
require "faraday_middleware"

module FastlaneCI
  # Controller responsible for handling users
  class UserJSONController < APIController
    disable(:authentication)

    HOME = "/api/user"

    get "#{HOME}/oauth" do
      code = params["code"].to_s

      if code.nil?
        json_error!(
          error_message: "Must OAuth code to exchange for OAuth key",
          error_key: "UserOAuth.Missing",
          error_code: 400
        )
      end

      if FastlaneCI.dot_keys.oauth_client_id.nil? || FastlaneCI.dot_keys.oauth_client_secret.nil?
        json_error!(
          error_message: "OAuth client has not been configured",
          error_key: "UserOAuth.Unconfigured",
          error_code: 403
        )
      end

      conn = Faraday.new(url: "https://github.com") do |faraday|
        faraday.request(:json)                    # JSON POST params
        faraday.response(:json, content_type: /\bjson$/)
        faraday.adapter(Faraday.default_adapter)  # make requests with Net::HTTP
      end

      res = conn.post do |req|
        req.url("/login/oauth/access_token")
        req.headers["Accept"] = "application/json"
        req.body = {
          client_id: FastlaneCI.dot_keys.oauth_client_id,
          client_secret: FastlaneCI.dot_keys.oauth_client_secret,
          code: code
        }
      end

      if res.status != 200
        json_error!(
          error_message: "There was an error while communicating with GitHub",
          error_key: "UserOAuth.GitHubCommunication",
          error_code: 400
        )
      end

      if res.body["error"] == "bad_verification_code"
        json_error!(
          error_message: "The provided OAuth code is incorrect or expired",
          error_key: "UserOAuth.BadCode",
          error_code: 400
        )
      end

      return json({ token: res.body["access_token"] })
    end

    post HOME.to_s do
      # fetch email based on the API token instead
      github_client = Octokit::Client.new(access_token: params[:github_token])

      begin
        # Note: This fails if the user.email scope is missing from token
        email = github_client.emails.find(&:primary).email
      rescue Octokit::NotFound
        json_error!(
          error_message: "Provided API token needs user email scope",
          error_key: "User.Token.MissingEmailScope",
          error_code: 400
        )
      rescue Octokit::Unauthorized
        json_error!(
          error_message: "Provided API token is invalid",
          error_key: "User.Token.Invalid",
          error_code: 403
        )
      end

      user = Services.user_service.create_user!(
        email: email,
        password: params[:password]
      )

      if user
        Services.user_service.create_provider_credential!(
          user_id: user.id,
          email: user.email,
          api_token: params[:github_token]
        )
        return json({ status: :success })
      else
        json_error!(
          error_message: "Error creating new user",
          error_key: "User.Error"
        )
      end
    end
  end
end
