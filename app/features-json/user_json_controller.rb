require_relative "../services/user_service"
require_relative "api_controller"
require_relative "json_params"

module FastlaneCI
  # Controller responsible for handling users
  class UserJSONController < APIController
    disable(:authentication)

    HOME = "/api/user"

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
