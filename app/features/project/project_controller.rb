require_relative "../../shared/authenticated_controller_base"
require_relative "../../shared/models/git_repo"
require_relative "../../shared/models/git_hub_repo_config"
require_relative "../../shared/fastfile_peeker"
require_relative "../../shared/fastfile_finder"
require_relative "../../features/build_runner/remote_runner"

require "pathname"
require "securerandom"
require "tmpdir"

module FastlaneCI
  # Controller for a single project view. Responsible for updates, triggering builds, and displaying project info
  class ProjectController < AuthenticatedControllerBase
    HOME = "/projects_erb"

    # Note: The order IS important for Sinatra, so this has to be
    # above the other URL
    post "#{HOME}/:project_id/trigger" do
      project_id = params[:project_id]
      # passing a specific sha is optional, so this might be nil
      current_sha = params[:sha] if params[:sha].to_s.length > 0

      project = user_project_with_id(project_id: project_id)
      current_github_provider_credential = check_and_get_provider_credential
      # Create random folder for checkout, prefixed with `manual_build`
      # or use the current_sha with the number of times we made a re-run for this commit.
      sha_or_uuid = (current_sha || SecureRandom.uuid).to_s
      if current_sha
        sha_build_count = Dir[File.join(File.expand_path(project.local_repo_path), "*#{current_sha}*")].count
        checkout_folder = File.join(
          File.expand_path(project.local_repo_path),
          "manual_build_#{sha_or_uuid}_#{sha_build_count}"
        )
      else
        checkout_folder = File.join(File.expand_path(project.local_repo_path), "manual_build_#{sha_or_uuid}")
      end

      # This could be hidden in a service
      unless current_sha
        # If we still don't know the sha, we'll need to grab the most current because
        # we just triggered a build from the Project page instead of a specific build
        repo = FastlaneCI::GitRepo.new(
          git_config: project.repo_config,
          local_folder: checkout_folder,
          provider_credential: current_github_provider_credential,
          notification_service: FastlaneCI::Services.notification_service
        )
        current_sha ||= repo.most_recent_commit.sha
      end

      manual_triggers_allowed = project.job_triggers.any? do |trigger|
        trigger.type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual]
      end

      unless manual_triggers_allowed
        status(403) # Forbidden
        body("Cannot build. There is no manual build trigger, for this branch, associated with this project.")
        return
      end

      branch_to_trigger = "master"

      git_fork_config = GitForkConfig.new(
        sha: current_sha,
        branch: branch_to_trigger,
        clone_url: project.repo_config.git_url
        # we don't need to pass a `ref`, as the sha and branch is all we need
      )
      trigger = project.job_triggers.find do |t|
        t.type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual]
      end

      remote_runner = RemoteRunner.new(
        project: project,
        git_fork_config: git_fork_config,
        trigger: trigger,
        github_service: FastlaneCI::GitHubService.new(provider_credential: current_github_provider_credential)
      )

      Services.build_runner_service.add_build_runner(build_runner: remote_runner)

      redirect("#{HOME}/#{project_id}/builds/#{remote_runner.current_build.number}")
    end

    post "#{HOME}/:project_id/save" do
      project_id = params[:project_id]
      project = user_project_with_id(project_id: project_id)
      project.lane = params["selected_lane"]
      project.project_name = params["project_name"]

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

    get "#{HOME}/*/valid" do
      content_type :json

      project_name = params[:splat].first

      if !project_name.nil?
        if Services.project_service.project(name: project_name).nil?
          return { valid: true }.to_json
        else
          return { valid: false }.to_json
        end
      else
        if project_name.empty?
          return { valid: false }.to_json
        else
          return { valid: true }.to_json
        end
      end
    end

    # This is an utility endpoint from where we can retrieve lane information through the front-end using basic JS.
    # This will be reviewed in the future when we have a proper front-end architecture.
    get "#{HOME}/*/lanes" do
      content_type :json

      org, repo_name, *branch_parts = params[:splat].first.split("/")
      branch = branch_parts.join("/")

      provider_credential = check_and_get_provider_credential(
        type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
      )

      github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)

      selected_repo = github_service.repos.detect do |repo|
        logger.debug("Looking for: #{repo_name} under (#{org}) found #{repo[:name]}, under #{repo[:owner][:login]}")
        repo_name == repo[:name] &&
          org == repo[:owner][:login]
      end

      if selected_repo.nil?
        raise "Could not find repo, check that your github token has access to repo: #{repo_name}, org/owner: #{org}"
      end

      fastfile_peeker = FastlaneCI::FastfilePeeker.new(
        provider_credential: provider_credential,
        notification_service: FastlaneCI::Services.notification_service
      )
      repo_config = GitHubRepoConfig.from_octokit_repo!(repo: selected_repo)

      fastfile_parser = fastfile_peeker.fastfile(
        repo_config: repo_config,
        sha_or_branch: branch
      )

      fetch_available_lanes(fastfile_parser).to_json
    end

    get "#{HOME}/*/add" do
      org, repo_name, = params[:splat].first.split("/")

      provider_credential = check_and_get_provider_credential(
        type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
      )

      github_service = FastlaneCI::GitHubService.new(provider_credential: provider_credential)

      selected_repo = github_service.repos.detect do |repo|
        repo_name == repo[:name] &&
          org == repo[:owner][:login]
      end

      # We need to check whether we can checkout the project without issues.
      # So a new project is created with default settings so we can fetch it.
      repo_config = GitHubRepoConfig.from_octokit_repo!(repo: selected_repo)

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

      selected_repo = github_service.repos.detect do |repo|
        repo_name == repo[:name] &&
          org == repo[:owner][:login]
      end

      repo_config = GitHubRepoConfig.from_octokit_repo!(repo: selected_repo)

      lane = params["selected_lane"]
      project_name = params["project_name"]
      branch = params["branch"]
      trigger_type = params["selected_trigger"]
      hour = params["hour"]
      minute = params["minute"]

      # Until we make a proper interface to attach JobTriggers to a Project, let's add a manual one for the
      # selected branch.
      triggers_to_add = TriggerFactory.new.create(
        params: { branch: branch, trigger_type: trigger_type, hour: hour, minute: minute }
      )

      # We now have enough information to create the new project.
      # add job_triggers here
      # We shouldn't be blocking manual trigger builds
      # if we do not provide an interface to add them.
      project = Services.project_service.create_project!(
        name: project_name,
        repo_config: repo_config,
        enabled: true,
        platform: lane.split(" ").first,
        lane: lane.split(" ").last,
        job_triggers: triggers_to_add
      )

      if !project.nil?
        # Do this so we trigger the clone of the repo.
        # Do this wherever it should be done, as we must redirect
        # to the project details only when this task is finished.
        repo = GitRepo.new(
          git_config: repo_config,
          provider_credential: provider_credential,
          local_folder: project.local_repo_path,
          async_start: false,
          notification_service: FastlaneCI::Services.notification_service
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
        available_lanes: [],
        fastfile_path: nil
      }

      if File.directory?(project_path)
        fastfile_path = FastlaneCI::FastfileFinder.search_path(path: project_path)
        fastfile_parser = Fastlane::FastfileParser.new(path: fastfile_path)
        available_lanes = fetch_available_lanes(fastfile_parser)

        relative_fastfile_path = Pathname.new(fastfile_path).relative_path_from(Pathname.new(project_path))

        locals[:available_lanes] = available_lanes
        locals[:fastfile_path] = relative_fastfile_path
      else
        provider_credential = check_and_get_provider_credential(
          type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
        )
        peeker = FastfilePeeker.new(
          provider_credential: provider_credential,
          notification_service: Services.notification_service
        )
        fastfile_parser = peeker.fastfile(
          repo_config: project.repo_config,
          sha_or_branch: project.job_triggers.map(&:branch).first
        )
        available_lanes = fetch_available_lanes(fastfile_parser)
        locals[:available_lanes] = available_lanes
      end

      # We should think carefully about exposing the value of an existing ENV variable
      # as this could potentially introduce a security risk. During development
      # the code below will make debugging easier
      locals[:global_env_variables] = Services.environment_variable_service.environment_variables
      locals[:project_env_variables] = project.environment_variables

      erb(:project, locals: locals, layout: FastlaneCI.default_layout)
    end

    def fetch_available_lanes(fastfile_parser)
      # we don't want to show `_before_all_block_`, `_after_all_block_` and `_error_block_`
      # or a private lane as an available lane
      lanes = []
      fastfile_parser.tree.each do |platform, value|
        value.each do |lane_name, lane_content|
          if lane_name.to_s.empty? ||
             lane_name.to_s.end_with?("_block_") ||
             lane_content[:private] == true
            next
          end

          lanes << {
              platform: platform.nil? ? :no_platform : platform,
              name: lane_name,
              display_name: [platform, lane_name].compact.join(" "),
              content: lane_content
          }
        end
      end
      return lanes
    end
  end
end
