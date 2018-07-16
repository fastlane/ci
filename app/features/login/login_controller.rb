# Internal
require_relative "../../shared/controller_base"
require_relative "../../services/user_service"
require_relative "../../services/dot_keys_variable_service"
require_relative "../../shared/models/github_provider_credential"

require "octokit"

module FastlaneCI
  # Displays CI login, user creation, as well as linking github api tokens, and logging out
  class LoginController < ControllerBase
    HOME = "/login_erb"

    get HOME do
      user = session[:user]

      # Are we logged into fastlane.ci?
      if user.nil?
        # nope, redirect to login to fastlane.com
        logger.debug("No fastlane.ci account found, redirecting to login")
        redirect("/login_erb/ci_login")
      end

      # Cool, we're logged in, but have we setup a provider?
      if user_has_valid_github_token?(provider_credentials: user.provider_credentials)
        # Yup, we setup a provider, so let's go to the dashboard
        redirect("/dashboard_erb")
      end

      # Oh, no valid github provider? That's ok, let's add a github credential
      locals = {
        title: "Connect fastlane.ci with GitHub"
      }
      erb(:login, locals: locals, layout: FastlaneCI.default_layout)
    end

    # Login with fastlane.ci credentials
    get "#{HOME}/ci_login" do
      client = Octokit::Client.new(access_token: FastlaneCI.dot_keys.ci_user_api_token)

      unless client.nil?
        email = client.emails.find(&:primary).email
      end
      locals = {
        title: "Login with your fastlane.ci account",
        email: email || ""
      }

      erb(:login_fastlane_ci, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "/logout" do
      session[:user] = nil

      locals = {
        title: "You are now logged out. You can log back in with your fastlane.ci account"
      }

      erb(:login_fastlane_ci, locals: locals, layout: FastlaneCI.default_layout)
    end

    # CI login
    post "/login_erb" do
      email = params[:email]
      password = params[:password]
      user = Services.user_service.login(email: email, password: password)
      if user.nil?
        redirect("#{HOME}/ci_login")
      else
        session[:user] = user
        if user_has_valid_github_token?(provider_credentials: user.provider_credentials)
          redirect("/dashboard_erb")
        else
          redirect("/login_erb")
        end
      end
    end

    get "#{HOME}/create_account" do
      locals = { title: "Create fastlane.ci account", create_failed: false }
      erb(:create_account, locals: locals, layout: FastlaneCI.default_layout)
    end

    post "#{HOME}/create_account" do
      email = params[:email]
      password = params[:password]
      user = Services.user_service.create_user!(email: email, password: password)
      if user.nil?
        locals = { title: "Create fastlane.ci account", create_failed: true }
        erb(:create_account, locals: locals, layout: FastlaneCI.default_layout)
      end
      session[:user] = user
      redirect("/login_erb")
    end

    # Submit an email and api token
    post "/login_erb/submit" do
      # check if we already have an account like this, if we do we might need to clean out their old
      # :personal_access_token
      email = params[:email]
      personal_access_token = params[:personal_access_token]
      github_provider_credential = FastlaneCI::GitHubProviderCredential.new(
        email: email,
        api_token: personal_access_token
      )
      user = session[:user]

      if user
        # needs github_provider_credential?
        needs_github_provider_credential = true
        updated_user = false
        provider_credentials = user.provider_credentials
        provider_credentials ||= []
        provider_credentials.each do |provider_credential|
          next unless provider_credential.type == FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
          if provider_credential.api_token.nil?
            # update out sample data
            provider_credential.api_token = github_provider_credential.api_token
            provider_credential.email = github_provider_credential.email
          end
          needs_github_provider_credential = false
          updated_user = true
        end

        if needs_github_provider_credential
          logger.debug("Account #{github_provider_credential.email} needs updating")
          provider_credentials << github_provider_credential
          user.provider_credentials = provider_credentials
          updated_user = true
        end

        Services.user_service.update_user!(user: user) if updated_user

        # Reload the user because https://github.com/fastlane/ci/issues/292
        user = Services.user_service.find_user(id: user.id)

        # update session user
        session[:user] = user
      end

      # not a big deal right now, but we should have a way of automatically generating the correct
      # CodeHostingService subclass based on the provider_credential type.
      git_hub_service = FastlaneCI::GitHubService.new(provider_credential: github_provider_credential)

      if git_hub_service.session_valid?
        redirect("/dashboard_erb")
      else
        redirect("/login_erb")
      end
    end

    def user_has_valid_github_token?(provider_credentials: [])
      provider_credentials.each do |provider_credential|
        if provider_credential.type == FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
          if provider_credential.api_token.nil?
            return false
          else
            return true
          end
        end
      end
      return false
    end
  end
end
