require_relative "../../shared/authenticated_controller_base"

module FastlaneCI
  class DashboardController < AuthenticatedControllerBase
    HOME = "/dashboard"

    get HOME do
      provider = self.check_and_get_provider
      user_config_service = self.current_user_config_service
      all_projects = user_config_service.projects(provider: provider)

      projects_with_access = all_projects

      locals = {
        projects_with_access: projects_with_access,
        projects_without_access: [], # we don't expose an API for this, yet
        title: "Dashboard"
      }
      erb(:dashboard, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/add_project" do
      provider = check_and_get_provider(type: FastlaneCI::Provider::PROVIDER_TYPES[:github])
      locals = {
        title: "Add new project",
        repos: FastlaneCI::GitHubSource.source_from_provider(provider: provider).repos
      }
      erb(:new_project, locals: locals, layout: FastlaneCI.default_layout)
    end

    # Example of json endpoint if you want to use ajax to async load stuff
    get "#{HOME}/build_list" do
      Services::BUILD_SERVICE.builds do |builds, paging_token|
        "builds #{builds}, paging token: #{paging_token}"
      end
    end
  end
end
