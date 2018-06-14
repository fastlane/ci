require_relative "api_controller"
require_relative "./view_models/build_view_model"

module FastlaneCI
  # Controller for providing all data relating to builds
  class BuildJSONController < APIController
    HOME = "/data/projects/:project_id/build"

    get "#{HOME}/:build_number" do |project_id, build_number|
      build = current_project.builds.find { |b| b.number == build_number.to_i }
      build_view_model = BuildViewModel.new(build: build)

      json(build_view_model)
    end

    post "#{HOME}/:build_number/rebuild" do |project_id, build_number|
      # passing a specific sha is optional, so this might be nil
      current_sha = params[:sha] if params[:sha].to_s.length > 0

      project = current_project

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

      # TODO: This should probably be hidden in a service
      repo = FastlaneCI::GitRepo.new(
        git_config: project.repo_config,
        local_folder: checkout_folder,
        provider_credential: current_user_provider_credential,
        notification_service: FastlaneCI::Services.notification_service
      )
      current_sha ||= repo.most_recent_commit.sha
      manual_triggers_allowed = project.job_triggers.any? do |trigger|
        trigger.type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual]
      end

      unless manual_triggers_allowed
        status(403) # Forbidden
        halt(403, "Cannot build. There is no manual build trigger, for this branch, associated with this project")
        return
      end

      branch_to_trigger = "master" # TODO: how/where do we get the default branch

      git_fork_config = GitForkConfig.new(
        sha: current_sha,
        branch: branch_to_trigger,
        clone_url: project.repo_config.git_url
        # we don't need to pass a `ref`, as the sha and branch is all we need
      )

      build_runner = FastlaneBuildRunner.new(
        project: project,
        sha: current_sha,
        github_service: FastlaneCI::GitHubService.new(provider_credential: current_user_provider_credential),
        notification_service: FastlaneCI::Services.notification_service,
        work_queue: FastlaneCI::GitRepo.git_action_queue, # using the git repo queue because of https://github.com/ruby-git/ruby-git/issues/355
        trigger: project.find_triggers_of_type(trigger_type: :manual).first,
        git_fork_config: git_fork_config
      )
      build_runner.setup(parameters: nil)
      Services.build_runner_service.add_build_runner(build_runner: build_runner)

      build_view_model = BuildViewModel.new(build: build_runner.current_build)
      json(build_view_model)
    end

    def current_project
      current_project = FastlaneCI::Services.project_service.project_by_id(params[:project_id])
      halt(404) unless current_project

      return current_project
    end
  end
end
