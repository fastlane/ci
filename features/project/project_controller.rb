require_relative "../../shared/controller_base"

module FastlaneCI
  class ProjectController < ControllerBase
    HOME = "/projects"

    # Note: The order IS important for Sinatra, so this has to be
    # above the other URL
    #
    # TODO: this should actually be a POST request
    get "#{HOME}/*/trigger" do |project_id|
      # TODO: fetching the project always like this, unify it
      project = Services::CONFIG_SERVICE.projects(FastlaneCI::GitHubSource.source_from_session(session)).find { |a| a.id == project_id }
      repo = FastlaneCI::GitRepo.new(
        git_url: project.repo_url,
        repo_id: project.id
      )

      redirect("#{HOME}/#{project_id}")
    end

    get "#{HOME}/*" do |project_id|
      project = Services::CONFIG_SERVICE.projects(FastlaneCI::GitHubSource.source_from_session(session)).find { |a| a.id == project_id }

      # TODO: don't hardcode this
      builds = [
        FastlaneCI::Build.new(
          project: project,
          number: 1,
          status: :failure,
          timestamp: Time.now
        ),
        FastlaneCI::Build.new(
          project: project,
          number: 2,
          status: :success,
          timestamp: Time.now
        ),
        FastlaneCI::Build.new(
          project: project,
          number: 3,
          status: :success,
          timestamp: Time.now
        ),
        FastlaneCI::Build.new(
          project: project,
          number: 4,
          status: :in_progress,
          timestamp: Time.now
        )
      ]
      project.builds = builds.reverse # TODO: just for now for the dummy data

      locals = {
        project: project,
        title: "Project #{project.project_name}"
      }
      erb(:project, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
