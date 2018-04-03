require_relative "../../shared/authenticated_controller_base"
require_relative "../../shared/models/git_repo"
require_relative "../../shared/fastfile_peeker"
require_relative "../../shared/fastfile_finder"

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
      # passing a specific sha is optional, so this might be nil
      current_sha = params[:sha] if params[:sha].to_s.length > 0

      project = user_project_with_id(project_id: project_id)
      current_github_provider_credential = check_and_get_provider_credential

      # Create random folder for checkout, prefixed with `manual_build`
      checkout_folder = File.join(File.expand_path(project.local_repo_path), "manual_build_#{SecureRandom.uuid}")
      # TODO: This should be hidden in a service
      repo = FastlaneCI::GitRepo.new(git_config: project.repo_config,
                                   local_folder: checkout_folder,
                            provider_credential: current_github_provider_credential,
                           notification_service: FastlaneCI::Services.notification_service)
      current_sha ||= repo.most_recent_commit.sha
      manual_triggers_allowed = project.job_triggers.any? do |trigger|
        trigger.type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual]
      end

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
        notification_service: FastlaneCI::Services.notification_service,
        work_queue: FastlaneCI::GitRepo.git_action_queue, # using the git repo queue because of https://github.com/ruby-git/ruby-git/issues/355
        trigger: project.find_triggers_of_type(trigger_type: :manual).first
      )
      build_runner.setup(parameters: nil)
      Services.build_runner_service.add_build_runner(build_runner: build_runner)

      redirect("#{HOME}/#{project_id}/builds/#{build_runner.current_build_number}")
    end

    post "#{HOME}/:project_id/save" do
      project_id = params[:project_id]
      project = user_project_with_id(project_id: project_id)
      project.lane = params["selected_lane"]
      project.project_name = params["project_name"]

      # TODO: what's the best way to store that project in the config?
      # Wait for Josh' input
      FastlaneCI::Services.project_service.update_project!(project: project)
      redirect("#{HOME}/#{project_id}")
    end

    get "#{HOME}/add" do
      provider_credential = check_and_get_provider_credential(
        type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
      )

      locals = {
        title: "Add new project",
        repos: FastlaneCI::GitHubService.new(provider_credential: provider_credential).repos
      }
      erb(:new_project, locals: locals, layout: FastlaneCI.default_layout)
    end

    # This is an utility endpoint from where we can retrieve lane information through the front-end using basic JS.
    # This will be reviewed in the future when we have a proper front-end architecture.
    get "#{HOME}/*/lanes" do
      content_type :json

      org, repo_name, branch, = params[:splat].first.split("/")

      provider_credential = check_and_get_provider_credential(
        type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
      )

      github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)
      selected_repo = github_service.repos.detect { |repo| repo_name == repo.name && org = repo.owner }

      repo_config = GitRepoConfig.from_octokit_repo!(repo: selected_repo)

      dir = Dir.mktmpdir
      repo = FastlaneCI::GitRepo.new(git_config: repo_config,
                                    local_folder: dir,
                                    provider_credential: provider_credential,
                                    async_start: false,
                                    notification_service: FastlaneCI::Services.notification_service)

      fastfile = FastlaneCI::FastfilePeeker.peek(
        git_repo: repo,
        branch: branch
      )

      fastfile_config = {}

      # The fastfile.tree might have (for now) nil keys due to lanes being outside of
      # a platform itself. So we take that nil key and transform it into a generic :no_platform
      # key.
      fastfile.tree.each_key do |key|
        if key.nil?
          fastfile_config[:no_platform] = fastfile.tree[key]
        else
          fastfile_config[key.to_sym] = fastfile.tree[key]
        end
      end

      fastfile_config.to_json
    end

    get "#{HOME}/*/add" do
      org, repo_name, = params[:splat].first.split("/")

      provider_credential = check_and_get_provider_credential(
        type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
      )

      github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)
      selected_repo = github_service.repos.detect { |repo| repo_name == repo.name && org = repo.owner }

      # We need to check whether we can checkout the project without issues.
      # So a new project is created with default settings so we can fetch it.
      repo_config = GitRepoConfig.from_octokit_repo!(repo: selected_repo)

      locals = {
        title: "Add new project",
        repo: repo_config.full_name,
        branches: github_service.branch_names(repo: repo_config.full_name)
      }

      erb(:new_project_form, locals: locals, layout: FastlaneCI.default_layout)
    end

    post "#{HOME}/*/add" do
      org, repo_name, = params[:splat].first.split("/")

      provider_credential = check_and_get_provider_credential(
        type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
      )

      github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)
      selected_repo = github_service.repos.detect { |repo| repo_name == repo.name && org = repo.owner }

      repo_config = GitRepoConfig.from_octokit_repo!(repo: selected_repo)

      lane = params["selected_lane"]
      project_name = params["project_name"]
      branch = params["branch"]
      trigger_type = params["selected_trigger"]
      hour = params["hour"]
      minute = params["minute"]

      case trigger_type
      when FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit]
        trigger = FastlaneCI::CommitJobTrigger.new(branch: branch)
      when FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual]
        trigger = FastlaneCI::ManualJobTrigger.new(branch: branch)
      when FastlaneCI::JobTrigger::TRIGGER_TYPE[:nightly]
        trigger = FastlaneCI::NightlyJobTrigger.new(branch: branch, hour: hour.to_i, minute: minute.to_i)
      else
        raise "Couldn't create a JobTrigger"
      end

      # We now have enough information to create the new project.
      # TODO: add job_triggers here
      # We shouldn't be blocking manual trigger builds
      # if we do not provide an interface to add them.
      project = Services.project_service.create_project!(
        name: project_name,
        repo_config: repo_config,
        enabled: true,
        platform: lane.split(" ").first,
        lane: lane.split(" ").last,
        # TODO: Until we make a proper interface to attach JobTriggers to a Project, let's add a manual one for the
        # selected branch.
        job_triggers: [trigger]
      )

      if !project.nil?
        # Do this so we trigger the clone of the repo.
        # TODO: Do this wherever it should be done, as we must redirect
        # to the project details only when this task is finished.
        repo = GitRepo.new(
          git_config: repo_config,
          provider_credential: provider_credential,
          local_folder: project.local_repo_path,
          async_start: false
        )

        repo.checkout_branch(branch: branch)

        redirect("#{HOME}/#{project.id}")
      else
        raise "Project couldn't be created"
      end
    end

    # Details of a project settings
    get "#{HOME}/:project_id" do
      project = user_project_with_id(project_id: params[:project_id])

      project_path = project.local_repo_path

      # we set the values below to default to nil, just because `erb` has an easier time then
      # checking for nil, instead of using `defined?` to see if a variable is defined
      locals = {
        project: project,
        title: "Project #{project.project_name}",
        available_lanes: nil,
        fastfile_parser: nil,
        fastfile_path: nil
      }

      if File.directory?(project_path)
        fastfile_path = FastlaneCI::FastfileFinder.search_path(path: project_path)
        fastfile_parser = Fastlane::FastfileParser.new(path: fastfile_path)
        available_lanes = fastfile_parser.available_lanes

        relative_fastfile_path = Pathname.new(fastfile_path).relative_path_from(Pathname.new(project_path))

        locals[:available_lanes] = available_lanes
        locals[:fastfile_parser] = fastfile_parser
        locals[:fastfile_path] = relative_fastfile_path
      end

      erb(:project, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
