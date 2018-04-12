require_relative "../../shared/authenticated_controller_base"

module FastlaneCI
  # Displays the main landing page, which is the project list right now
  class DashboardController < AuthenticatedControllerBase
    HOME = "/dashboard_erb"

    get HOME do
      current_provider_credential = check_and_get_provider_credential

      current_user_config_service = self.current_user_config_service

      all_projects = current_user_config_service.projects(provider_credential: current_provider_credential)

      projects_with_access = all_projects

      locals = {
        projects_with_access: projects_with_access,
        projects_without_access: [], # we don't expose an API for this, yet
        title: "Dashboard",
        server_version: FastlaneCI.server_version
      }
      erb(:dashboard, locals: locals, layout: FastlaneCI.default_layout)
    end

    # Example of json endpoint if you want to use ajax to async load stuff
    get "#{HOME}/build_list" do
      Services::BUILD_SERVICE.builds do |builds, paging_token|
        "builds #{builds}, paging token: #{paging_token}"
      end
    end
  end
end
