require "sinatra/base"
require_relative "../../services/services"

module FastlaneCI
  class DashboardController < Sinatra::Base
    HOME = "/dashboard"

    before("#{HOME}*") do
      # If the user isn't logged in, redirect to login
      redirect("/login") if FastlaneCI::Services.code_hosting_sources.count == 0
    end

    get HOME do
      locals = {
        projects: Services::CONFIG_SERVICE.projects,
        title: "Dashboard"
      }
      erb(:dashboard, locals: locals)
    end

    get "#{HOME}/add_project" do
      locals = {
        title: "Add new project",
        repos: FastlaneCI::Services.code_hosting_sources.first.repos # TODO: .first, ugh. Should we allow only one sesion for now?
      }
      erb(:new_project, locals: locals)
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
