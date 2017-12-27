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
      erb(:login, locals: locals, layout: :"../../global/layout") # TODO: find a way to set the layout for all controllers
    end

    post "/login/submit" do
      email = params[:email]
      personal_access_token = params[:personal_access_token]

      git_hub_service = FastlaneCI::GitHubSource.new(email: email, personal_access_token: personal_access_token)
      if git_hub_service.session_valid?
        FastlaneCI::Services.code_hosting_sources ||= []
        FastlaneCI::Services.code_hosting_sources << git_hub_service
        redirect("/dashboard")
      else
        # TODO: show error to user
        redirect("/login")
      end
    end
  end
end
