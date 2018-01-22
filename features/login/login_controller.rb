# Internal
require_relative "../../shared/controller_base"
require_relative "../../services/user_service"
require_relative "../../shared/models/github_provider"

module FastlaneCI
  class LoginController < ControllerBase
    HOME = "/login"
    USER_SERVICE = UserService.new

    get HOME do
      user = session[:user]

      # Are we logged into fastlane.ci?
      if user.nil?
        # nope, redirect to login to fastlane.com
        logger.debug("No fastlane.ci account found, redirecting to login")
        redirect("/login/ci_login")
      end

      # Cool, we're logged in, but have we setup a provider?
      if user_has_valid_github_token?(providers: user.providers)
        # Yup, we setup a provider, so let's go to the dashboard
        redirect("/dashboard")
      end

      # Oh, no valid github provider? That's ok, let's add a github credential
      locals = {
        title: "Connect fastlane.ci with GitHub"
      }
      erb(:login, locals: locals, layout: FastlaneCI.default_layout)
    end

    # Login with fastlane.ci credentials
    get "#{HOME}/ci_login" do
      locals = {
        title: "Login with your fastlane.ci account"
      }

      erb(:login_fastlane_ci, locals: locals, layout: FastlaneCI.default_layout)
    end

    post "/login" do
      email = params[:email]
      password = params[:password]
      user = USER_SERVICE.login(email: email, password: password)
      if user.nil?
        redirect("#{HOME}/ci_login")
      else
        session[:user] = user
        if user_has_valid_github_token?(providers: user.providers)
          redirect("/dashboard")
        else
          redirect("/login")
        end
      end
    end

    # make sure we have at least one github provider (currently only supported)
    def user_has_valid_github_token?(providers: [])
      providers.each do |provider|
        if provider.type == FastlaneCI::Provider::PROVIDER_TYPES[:github]
          if provider.api_token.nil?
            return false
          else
            return true
          end
        end
      end
      return false
    end

    get "#{HOME}/create_account" do
      present_create_account
    end

    def present_create_account(failed: false)
      # failed not used yet, but should display create error
      locals = {
        title: "Create fastlane.ci account"
      }

      erb(:create_account, locals: locals, layout: FastlaneCI.default_layout)
    end

    post "#{HOME}/create_account" do
      email = params[:email]
      password = params[:password]
      user = USER_SERVICE.create_user!(email: email, password: password)
      if user.nil?
        present_create_account(failed: true)
      end
      session[:user] = user
      redirect("/login")
    end

    # Login with github credentials
    post "/login/submit" do
      # check if we already have an account like this, if we do we might need to clean out their old :personal_access_token
      email = params[:email]
      personal_access_token = params[:personal_access_token]
      github_provider = FastlaneCI::GitHubProvider.new(email: email, api_token: personal_access_token)
      user = session[:user]

      if user
        # needs github_provider?
        needs_github_provider = true
        updated_user = false
        providers = user.providers
        providers ||= []
        providers.each do |provider|
          next unless provider.type == FastlaneCI::Provider::PROVIDER_TYPES[:github]
          if provider.api_token.nil?
            # update out sample data
            provider.api_token = github_provider.api_token
            provider.email = github_provider.email
          end
          needs_github_provider = false
          updated_user = true
        end

        if needs_github_provider
          logger.debug("account #{email} needs updating")
          providers << github_provider
          user.providers = providers
          updated_user = true
        end

        USER_SERVICE.update_user!(user: user) if updated_user

        # update session user
        session[:user] = user
      end

      git_hub_service = FastlaneCI::GitHubSource.source_from_provider(provider: github_provider)

      if git_hub_service.session_valid?

        session["GITHUB_SESSION_API_TOKEN"] = personal_access_token
        session["GITHUB_SESSION_EMAIL"] = email
        # TODO: we don't actually want to start this here
        # but since we don't have a fastlane.ci session yet
        # we're just gonna abuse the user's token for now
        # in the future we're not gonna share the user's session

        # TODO: find a better place for this
        # FastlaneCI::CheckForNewCommitsWorker.new(session: session)

        redirect("/dashboard")
      else
        # TODO: show error to user
        redirect("/login")
      end
    end
  end
end
