require_relative "../../shared/authenticated_controller_base"

module FastlaneCI
  class DashboardController < AuthenticatedControllerBase
    HOME = "/dashboard"

    get HOME do
      locals = {
        projects: Services::CONFIG_SERVICE.projects,
        title: "Dashboard"
      }
      erb(:dashboard, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/add_project" do
      locals = {
        title: "Add new project",
        repos: FastlaneCI::Services.code_hosting_sources.first.repos # TODO: .first, ugh. Should we allow only one sesion for now?
      }
      erb(:new_project, locals: locals, layout: FastlaneCI.default_layout)
    end

    # Example of json endpoint if you want to use ajax to async load stuff
    get "#{HOME}/build_list" do
      Services::BUILD_SERVICE.builds do |builds, paging_token|
        "builds #{builds}, paging token: #{paging_token}"
      end
    end

    # TODO: we'll have to build the whole "Add Project flow"
    # This is the code that can be used to add a new project
    #
    # post "#{HOME}/new" do
    #   projects = Services::CONFIG_SERVICE.projects
    #   projects << Project.new(repo_url: "https://github.com/fastlane/fastlane", enabled: true)
    #   Services::CONFIG_SERVICE.projects = projects
    # end
  end
end
