# Internal
require_relative "../../shared/controller_base"
require_relative "../../services/user_service"

module FastlaneCI
  class LoginController < ControllerBase
    HOME = "/login"
    USER_SERVICE = UserService.new

    get HOME do
      if FastlaneCI::GitHubSource.source_from_session(session).session_valid?
        redirect("/dashboard")
      end

      locals = {
        title: "Login with GitHub"
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
        redirect("/dashboard")
      end
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
      redirect("/dashboard")
    end

    # Login with github credentials
    post "/login/submit" do
      # check if we already have an account like this, if we do we might need to clean out their old :personal_access_token
      email = params[:email]
      personal_access_token = params[:personal_access_token]

      git_hub_service = FastlaneCI::GitHubSource.new(email: email, personal_access_token: personal_access_token)

      if git_hub_service.session_valid?
        session["GITHUB_SESSION_API_TOKEN"] = personal_access_token
        session["GITHUB_SESSION_EMAIL"] = email
        # TODO: we don't actually want to start this here
        # but since we don't have a fastlane.ci session yet
        # we're just gonna abuse the user's token for now
        # in the future we're not gonna share the user's session
        FastlaneCI::CheckForNewCommitsWorker.new(session: session)
        redirect("/dashboard")
      else
        # TODO: show error to user
        redirect("/login")
      end
    end
  end
end
