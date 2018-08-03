require_relative "api_controller"
require_relative "../features/build_runner/remote_runner"
require_relative "./view_models/build_summary_view_model"
require_relative "./view_models/build_view_model"

require "faye/websocket"
Faye::WebSocket.load_adapter("thin")

module FastlaneCI
  # Controller for providing all data relating to builds
  class BuildJSONController < APIController
    HOME = "/data/projects/:project_id/build"

    def self.build_url(project_id:, build_number:)
      return "/project/#{project_id}/build/#{build_number}"
    end

    get "#{HOME}/:build_number" do |project_id, build_number|
      build_view_model = BuildViewModel.new(build: current_build)

      json(build_view_model)
    end

    post "#{HOME}/:build_number/rebuild" do |project_id, build_number|
      # TODO: We're not using `build_number` anywhere here
      # Seems like we make use of just the `sha` value, if so, maybe the `build_number`
      # shouldn't be here?

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
        json_error!(
          error_message: "Cannot build. There is no manual build trigger, for this branch" \
          "associated with this project",
          error_code: 403
        )
        return
      end

      branch_to_trigger = "master" # TODO: how/where do we get the default branch

      git_fork_config = GitForkConfig.new(
        sha: current_sha,
        branch: branch_to_trigger,
        clone_url: project.repo_config.git_url
        # we don't need to pass a `ref`, as the sha and branch is all we need
      )

      build_runner = RemoteRunner.new(
        project: project,
        git_fork_config: git_fork_config,
        trigger: project.find_triggers_of_type(trigger_type: :manual).first,
        github_service: FastlaneCI::GitHubService.new(provider_credential: current_user_provider_credential)
      )
      Services.build_runner_service.add_build_runner(build_runner: build_runner)

      build_summary_view_model = BuildSummaryViewModel.new(build: build_runner.current_build)
      json(build_summary_view_model)
    end

    get "#{HOME}/:build_number/log.ws" do |project_id, build_number|
      halt(415, "unsupported media type") unless Faye::WebSocket.websocket?(request.env)
      ws = Faye::WebSocket.new(request.env, nil, { ping: 30 })

      ws.on(:open) do |event|
        logger.debug([:open, ws.object_id])

        ## handle the case that the build completes, and runner.log is saved.
        current_project = FastlaneCI::Services.project_service.project_by_id(project_id)
        current_build = current_project.builds.find { |b| b.number == build_number.to_i }

        if current_build
          build_log_artifact = current_build.artifacts.find do |current_artifact|
            # We can improve the detection in the future, to actually mark an artifact as "default output"
            current_artifact.type.include?("log") && current_artifact.reference.end_with?("runner.log")
          end

          if build_log_artifact
            logger.debug("streaming back artifact: #{build_log_artifact.reference}")
            File.open(build_log_artifact.reference, "r") do |file|
              file.each_line do |line|
                ws.send(line.chomp)
              end
            end
            ws.close(1000, "runner complete.")
            next
          end
        end

        ## if we have no runner.log, then check to see if the build_runner is still working.

        current_build_runner = Services.build_runner_service.find_build_runner(
          project_id: project_id,
          build_number: build_number.to_i
        )

        if current_build_runner.nil?
          ws.close(1000, "no runner found for project #{project_id} and build #{build_number}.")
          next
        end

        # if the build runner has already completed, we can close the connection, and do not proceed
        if current_build_runner.completed?
          ws.close(1000, "runner complete.")
          next
        end

        # once the build runner completes, close the websocket connection.
        current_build_runner.on_complete do
          ws.close(1000, "runner complete.")
        end

        # subscribe the current socket to events from the remote_runner
        # as soon as a subscriber is returned, they will receive all historical items as well.
        @subscriber = current_build_runner.subscribe do |_topic, payload|
          ws.send(JSON.dump(payload))
        end
      end

      ws.on(:close) do |event|
        logger.debug([:close, ws.object_id, event.code, event.reason])

        current_build_runner = Services.build_runner_service.find_build_runner(
          project_id: project_id,
          build_number: build_number.to_i
        )
        next if current_build_runner.nil?

        current_build_runner.unsubscribe(@subscriber)

        Services.build_runner_service.remove_build_runner(build_runner: current_build_runner)
      end

      # Return async Rack response
      return ws.rack_response
    end

    def current_build
      current_build = current_project.builds.find { |b| b.number == params[:build_number].to_i }
      if current_build.nil?
        json_error!(
          error_message: "Can't find build with ID #{params[:build_number]} for project #{params[:project_id]}",
          error_key: "Build.Missing",
          error_code: 404
        )
      end

      return current_build
    end

    def current_project
      current_project = FastlaneCI::Services.project_service.project_by_id(params[:project_id])
      unless current_project
        json_error!(
          error_message: "Can't find project with ID #{params[:project_id]}",
          error_key: "Project.Missing",
          error_code: 404
        )
      end

      return current_project
    end
  end
end
