require_relative "../../shared/authenticated_controller_base"
require_relative "../../shared/models/git_repo"

require "pathname"
require "securerandom"
require "tmpdir"

module FastlaneCI
  # Controller for a single project view. Responsible for updates, triggering builds, and displaying project info
  class ProjectController < AuthenticatedControllerBase
    HOME = "/projects_erb"

    # Note: The order IS important for Sinatra, so this has to be
    # above the other URL
    #
    # TODO: this should actually be a POST request
    get "#{HOME}/:project_id/trigger" do
      project_id = params[:project_id]
      project = self.user_project_with_id(project_id: project_id)
      current_github_provider_credential = self.check_and_get_provider_credential

      # Create random folder for checkout, prefixed with `manual_build`
      checkout_folder = File.join(File.expand_path(project.local_repo_path), "manual_build_#{SecureRandom.uuid}")
      # TODO: This should be hidden in a service
      repo = FastlaneCI::GitRepo.new(git_config: project.repo_config,
                                   local_folder: checkout_folder,
                            provider_credential: current_github_provider_credential)
      current_sha = repo.most_recent_commit.sha
      manual_triggers_allowed = project.job_triggers.any? { |trigger| trigger.type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual] }

      unless manual_triggers_allowed
        status(403) # Forbidden
        body("Cannot build. There is no manual build trigger, for this branch, associated with this project.")
        return
      end

      # TODO: This should be hidden in a service
      build_runner = FastlaneBuildRunner.new(
        project: project,
        sha: current_sha,
        github_service: FastlaneCI::GitHubService.new(provider_credential: current_github_provider_credential),
        work_queue: FastlaneCI::GitRepo.git_action_queue, # using the git repo queue because of https://github.com/ruby-git/ruby-git/issues/355
        repo: repo
      )
      build_runner.setup(parameters: nil)
      Services.build_runner_service.add_build_runner(build_runner: build_runner)

      redirect("#{HOME}/#{project_id}/builds/#{build_runner.current_build_number}")
    end

    post "#{HOME}/:project_id/save" do
      project_id = params[:project_id]
      project = self.user_project_with_id(project_id: project_id)
      project.lane = params["selected_lane"]
      project.project_name = params["project_name"]

      # TODO: what's the best way to store that project in the config?
      # Wait for Josh' input
      FastlaneCI::Services.project_service.update_project!(project: project)
      redirect("#{HOME}/#{project_id}")
    end

    get "#{HOME}/add" do
      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      locals = {
          title: "Add new project",
          repos: FastlaneCI::GitHubService.new(provider_credential: provider_credential).repos
      }
      erb(:new_project, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/lanes/*/*/*" do |org, repo_name, branch|
      content_type :json

      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      selected_repo = github_service.repos.detect { |repo| repo_name == repo.name }
      repo_config = GitRepoConfig.from_octokit_repo!(repo: org + "/" + repo_name)

      git_repo = GitRepo.new(
        git_config: repo_config,
        provider_credential: provider_credential,
        local_folder: dir,
        async_start: false
      )
      git_repo.checkout_branch(branch)

      fastfile = FastlaneCI::FastfilePeeker.peek(git_repo: git_repo)

      fastfile.all_lanes_flat.to_json
    end

    get "#{HOME}/add/*" do |repo_name|
      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)
      selected_repo = github_service.repos.detect { |repo| repo_name == repo.name }

      # We need to check whether we can checkout the project without issues.
      # So a new project is created with default settings so we can fetch it.
      repo_config = GitRepoConfig.from_octokit_repo!(repo: selected_repo)

      dir = Dir.mktmpdir
      repo = GitRepo.new(
        git_config: repo_config,
        provider_credential: provider_credential,
        local_folder: dir,
        async_start: false
      )

      # TODO: This should be refactored in some kind of FastlaneUtils` class.`
      # We have synchronously cloned the repo, now we need to get the lanes.
      repo_path = repo.local_folder
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

      # Delete the project
      FileUtils.rm_rf(repo_path) if File.directory?(File.join(repo_path, ".git"))

      erb(:new_project_form, locals: locals, layout: FastlaneCI.default_layout)
    end

    post "#{HOME}/add/*/*" do |org, repo_name|
      provider_credential = check_and_get_provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)
      selected_repo = github_service.repos.detect { |repo| repo.full_name == org + "/" + repo_name }

      repo_config = GitRepoConfig.from_octokit_repo!(repo: selected_repo)

      lane = params["selected_lane"]
      project_name = params["project_name"]

      dir = Dir.mktmpdir
      # Do this so we trigger the clone of the repo.
      # TODO: Do this wherever it should be done, as we must redirect
      # to the project details only when this task is finished.
      _ = GitRepo.new(
        git_config: repo_config,
        provider_credential: provider_credential,
        local_folder: dir,
        async_start: false
      )

      # We now have enough information to create the new project.
      # TODO: add job_triggers here
      # We shouldn't be blocking manual trigger builds
      # if we do not provide an interface to add them.
      project = Services.project_service.create_project!(
        name: project_name,
        repo_config: repo_config,
        enabled: true,
        lane: lane
      )

      if !project.nil?
        redirect("#{HOME}/#{project.id}")
      else
        raise "Project couldn't be created"
      end
    end

    # Details of a project settings
    get "#{HOME}/:project_id" do
      project = self.user_project_with_id(project_id: params[:project_id])

      # TODO: We now access a file directly from the submodule
      # That's of course far from ideal, and not something we want to do long term
      # Long term, the best appraoch would probably to have the FastfileParser be
      # its own Ruby gem, or even part of the fastlane/fastlane main repo
      # For now, this is good enough, as we'll be moving so fast with this one

      relative_fastfile_path = nil
      available_lanes = []
      # TODO: Follow up in another PR

      # absolute_fastfile_path = project.local_fastfile_path
      # unless absolute_fastfile_path.nil?
      #   parser = Fastlane::FastfileParser.new(path: absolute_fastfile_path)
      #   available_lanes = parser.available_lanes

      #   project_path = project.local_repo_path
      #   relative_fastfile_path = Pathname.new(absolute_fastfile_path).relative_path_from(Pathname.new(project_path))
      # end

      locals = {
        project: project,
        title: "Project #{project.project_name}",
        available_lanes: available_lanes,
        fastfile_path: relative_fastfile_path # TODO: rename param `fastfile_path` to `relative_fastfile_path`
      }

      erb(:project, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
