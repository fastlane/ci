require_relative "../../shared/authenticated_controller_base"

module FastlaneCI
  class DashboardController < AuthenticatedControllerBase
    HOME = "/dashboard"

    get HOME do
      # TODO: passing the session to a service seems off, but also
      # we need access to the `session` from Sinatra to get the GitHub
      # auth token.
      # @felix-> you can pass the user's FastlaneCI::Provider through and then use the API token there
      all_projects = Services::CONFIG_SERVICE.projects(FastlaneCI::GitHubSource.source_from_session(session))

      # TODO: we need a service call for this, projects shouldn't know permissions
      projects_with_access = all_projects.select(&:current_user_has_access?)
      projects_without_access = all_projects.reject(&:current_user_has_access?)

      locals = {
        projects_with_access: projects_with_access,
        projects_without_access: projects_without_access,
        title: "Dashboard"
      }
      erb(:dashboard, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/add_project" do
      locals = {
        title: "Add new project",
        repos: FastlaneCI::GitHubSource.source_from_session(session).repos
      }
      erb(:new_project, locals: locals, layout: FastlaneCI.default_layout)
    end

    # Example of json endpoint if you want to use ajax to async load stuff
    get "#{HOME}/build_list" do
      Services::BUILD_SERVICE.builds do |builds, paging_token|
        "builds #{builds}, paging token: #{paging_token}"
      end
    end

    # post "#{HOME}/new" do
    #   # id of GitRepoConfig
    #   repo_id = params[:repo_id]
    #   project_name = params[:project_name]
    #   project_name = params[:lane]
    #
    # end
  end
end
