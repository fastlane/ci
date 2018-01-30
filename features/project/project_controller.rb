require_relative "../../shared/authenticated_controller_base"
require "pathname"

module FastlaneCI
  class ProjectController < AuthenticatedControllerBase
    HOME = "/projects"

    # Note: The order IS important for Sinatra, so this has to be
    # above the other URL
    #
    # TODO: this should actually be a POST request
    get "#{HOME}/*/trigger" do |project_id|
      project = self.user_project_with_id(project_id: project_id)
      current_github_provider_credential = self.check_and_get_provider_credential

      repo = FastlaneCI::GitRepo.new(git_config: project.repo_config, provider_credential: current_github_provider_credential)
      current_sha = repo.most_recent_commit.sha

      # TODO: not the best approach to spawn a thread
      Thread.new do
        FastlaneCI::TestRunnerService.new(
          project: project,
          sha: current_sha,
          provider_credential: current_github_provider_credential
        ).run
      end

      redirect("#{HOME}/#{project_id}")
    end

    # Edit a project settings
    get "#{HOME}/*/edit" do |project_id|
      project = self.user_project_with_id(project_id: project_id)

      # TODO: We now access a file directly from the submodule
      # That's of course far from ideal, and not something we want to do long term
      # Long term, the best appraoch would probably to have the FastfileParser be
      # its own Ruby gem, or even part of the fastlane/fastlane main repo
      # For now, this is good enough, as we'll be moving so fast with this one
      project_path = project.repo_config.local_repo_path

      # First assume the fastlane directory and its file is in the root of the project
      fastfiles = Dir[File.join(project_path, "fastlane/Fastfile")]
      # If not, it might be in a subfolder
      fastfiles = Dir[File.join(project_path, "**/fastlane/Fastfile")] if fastfiles.count == 0

      if fastfiles.count > 1
        logger.error("Ugh, multiple Fastfiles found, we're gonna have to build a selection in the future")
        # for now, just take the first one
      end

      fastfile_path = fastfiles.first

      parser = Fastlane::FastfileParser.new(path: fastfile_path)
      available_lanes = parser.available_lanes

      relative_fastfile_path = Pathname.new(fastfile_path).relative_path_from(Pathname.new(project_path))

      locals = {
        project: project,
        title: "Project #{project.project_name}",
        available_lanes: available_lanes,
        fastfile_path: relative_fastfile_path
      }

      erb(:edit_project, locals: locals, layout: FastlaneCI.default_layout)
    end

    post "#{HOME}/*/save" do |project_id|
      project = self.user_project_with_id(project_id: project_id)
      project.lane = params["selected_lane"]
      project.project_name = params["project_name"]

      # TODO: what's the best way to store that project in the config?
      # Wait for Josh' input
    end

    get "#{HOME}/*" do |project_id|
      project = self.user_project_with_id(project_id: project_id)

      locals = {
        project: project,
        title: "Project #{project.project_name}"
      }
      erb(:project, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
