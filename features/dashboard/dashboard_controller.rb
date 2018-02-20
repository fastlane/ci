require_relative "../../shared/authenticated_controller_base"

module FastlaneCI
  # Displays the main landing page, which is the project list right now
  class DashboardController < AuthenticatedControllerBase
    HOME = "/dashboard"

    get HOME do
      current_provider_credential = self.check_and_get_provider_credential

      current_user_config_service = self.current_user_config_service

      all_projects = current_user_config_service.projects(provider_credential: current_provider_credential)

      projects_with_access = all_projects

      locals = {
        projects_with_access: projects_with_access,
        projects_without_access: [], # we don't expose an API for this, yet
        title: "Dashboard"
      }
      erb(:dashboard, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/add_project" do
      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])
      locals = {
        title: "Add new project",
        repos: FastlaneCI::GitHubService.new(provider_credential: provider_credential).repos
      }
      erb(:new_project, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/add_project/*" do |repo_name|
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

    post "#{HOME}/add_project/*" do |repo_name|
      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)
      selected_repo = github_service.repos.select { |repo| repo_name == repo.name }.first

      repo_config = GitRepoConfig.from_octokit_repo!(repo: selected_repo)

      lane = params["selected_lane"]
      project_name = params["project_name"]

      # We now have enough information to create the new project.
      project = Services.project_service.create_project!(
        name: project_name,
        repo_config: repo_config,
        enabled: true,
        lane: lane
      )

      if !project.nil?
        redirect("/projects/#{project.id}")
      else
        raise "Project couldn't be created"
      end
    end

    # Example of json endpoint if you want to use ajax to async load stuff
    get "#{HOME}/build_list" do
      Services::BUILD_SERVICE.builds do |builds, paging_token|
        "builds #{builds}, paging token: #{paging_token}"
      end
    end
  end
end
