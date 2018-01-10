# External
require "sinatra/base"

# Internal
require_relative "../../services/services"

module FastlaneCI
  class LoginController < Sinatra::Base
    get "/login" do
      locals = {
        title: "Login"
      }
      erb(:login, locals: locals, layout: FastlaneCI.default_layout)
    end

    post "/login/submit" do
      email = params[:email]
      personal_access_token = params[:personal_access_token]

      git_hub_service = FastlaneCI::GitHubSource.new(email: email, personal_access_token: personal_access_token)
      if git_hub_service.session_valid?
        require 'pry'; binding.pry
        session["GITHUB_SESSION_API_TOKEN"] = personal_access_token
        redirect("/dashboard")
      else
        # TODO: show error to user
        redirect("/login")
      end
    end
  end
end
