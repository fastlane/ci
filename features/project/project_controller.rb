require "sinatra/base"
require_relative "../../services/services"

module FastlaneCI
  class ProjectController < Sinatra::Base
    HOME = "/projects"

    before("#{HOME}*") do
      # If the user isn't logged in, redirect to login
      redirect("/login") if FastlaneCI::Services.code_hosting_sources.count == 0
    end

    get "#{HOME}/*" do |project_id|
      project = Services::CONFIG_SERVICE.projects.find { |a| a.id == project_id }
      locals = {
        project: project,
        title: "Project #{project.project_name}"
      }
      erb(:project, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
