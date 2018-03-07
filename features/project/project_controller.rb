require_relative "../../shared/authenticated_controller_base"
require "pathname"

module FastlaneCI
  # Controller for a single project view. Responsible for updates, triggering builds, and displaying project info
  class ProjectController < AuthenticatedControllerBase
    HOME = "/projects"

    # Note: The order IS important for Sinatra, so this has to be
    # above the other URL
    #
    # TODO: this should actually be a POST request
    get "#{HOME}/:project_id/trigger" do
      project_id = params[:project_id]

      project = self.user_project_with_id(project_id: project_id)
      current_github_provider_credential = self.check_and_get_provider_credential

      repo = FastlaneCI::GitRepo.new(git_config: project.repo_config, provider_credential: current_github_provider_credential)
      current_sha = repo.most_recent_commit.sha
      manual_triggers_allowed = project.job_triggers.any? { |trigger| trigger.type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual] }

      unless manual_triggers_allowed
        status(403) # Forbidden
        body("Cannot build. There is no manual build trigger, for this branch, associated with this project.")
        return
      end

      # TODO: pass GitHub service?
      build_runner = FastlaneBuildRunner.new(project: project, sha: current_sha, github_service: nil)
      build_runner.setup(platform: "ios", lane: "beta", parameters: nil) # specific to fastlane
      Services.build_runner_service.add_build_runner(build_runner: build_runner)

      redirect("#{HOME}/#{project_id}/builds/#{build_runner.current_build.number}")
    end

    # Edit a project settings
    get "#{HOME}/:project_id/edit" do
      project = self.user_project_with_id(project_id: params[:project_id])

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

    post "#{HOME}/:project_id/save" do
      project_id = params[:project_id]
      project = self.user_project_with_id(project_id: project_id)
      project.lane = params["selected_lane"]
      project.project_name = params["project_name"]

      # TODO: what's the best way to store that project in the config?
      # Wait for Josh' input
      FastlaneCI::Services.project_service.update_project!(project: project)
      redirect("#{HOME}/details/#{project_id}")
    end

    get "#{HOME}/details/:project_id" do
      project = self.user_project_with_id(project_id: params[:project_id])

      locals = {
        project: project,
        title: "Project #{project.project_name}"
      }
      erb(:project, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/add" do
      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])
      locals = {
          title: "Add new project",
          repos: FastlaneCI::GitHubService.new(provider_credential: provider_credential).repos
      }
      erb(:new_project, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/add/*" do |repo_name|
      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)
      selected_repo = github_service.repos.select { |repo| repo_name == repo.name }.first

      # We need to check whether we can checkout the project without issues.
      # So a new project is created with default settings so we can fetch it.
      repo_config = GitRepoConfig.from_octokit_repo!(repo: selected_repo)

      repo = GitRepo.new(
        git_config: repo_config,
        provider_credential: provider_credential,
        async_start: false
      )

      # TODO: This should be refactored in some kind of FastlaneUtils` class.`
      # We have synchronously cloned the repo, now we need to get the lanes.
      repo_path = repo.git_config.local_repo_path
      # First assume the fastlane directory and its file is in the root of the project
      fastfiles = Dir[File.join(repo_path, "fastlane/Fastfile")]
      # If not, it might be in a subfolder
      fastfiles = Dir[File.join(repo_path, "**/fastlane/Fastfile")] if fastfiles.count == 0

      if fastfiles.count > 1
        logger.error("Ugh, multiple Fastfiles found, we're gonna have to build a selection in the future")
        # for now, just take the first one
      end

      fastfile_path = fastfiles.first

      parser = Fastlane::FastfileParser.new(path: fastfile_path)
      available_lanes = parser.available_lanes

      locals = {
          title: "Add new project",
          repo: repo,
          lanes: available_lanes,
          fastfile_path: fastfile_path
      }

      erb(:new_project_form, locals: locals, layout: FastlaneCI.default_layout)
    end

    post "#{HOME}/add/*" do |repo_name|
      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)
      selected_repo = github_service.repos.select { |repo| repo_name == repo.name }.first

      repo_config = GitRepoConfig.from_octokit_repo!(repo: selected_repo)

      lane = params["selected_lane"]
      project_name = params["project_name"]

      # We now have enough information to create the new project.
      # TODO: add job_triggers here
      project = Services.project_service.create_project!(
        name: project_name,
        repo_config: repo_config,
        enabled: true,
        lane: lane
      )

      if !project.nil?
        redirect("#{HOME}/details/#{project.id}")
      else
        raise "Project couldn't be created"
      end
    end
  end
end
