require "micromachine"
require_relative "../../../agent/client"
require_relative "../../shared/models/artifact"

module FastlaneCI
  # RemoteRunner class
  #
  class RemoteRunner
    include FastlaneCI::Logging

    # Reference to the FastlaneCI::Project of this particular build run
    attr_reader :project

    # In case we need to fork, we can configure the git repo
    attr_reader :git_fork_config

    # Access the FastlaneCI::Build of that specific Runner
    attr_reader :current_build

    # The commit sha we want to run the build for
    attr_reader :sha

    # All lines that were generated so far, this might not be a complete run
    # This is an array of hashes
    attr_accessor :all_build_output_log_rows

    # TODO: Add comment
    attr_accessor :build_change_observer_blocks

    # TODO: extract this thing out of this class.
    attr_reader :github_service

    def initialize(project:, git_fork_config:, trigger:, github_service:)
      @project = project
      @git_fork_config = git_fork_config
      @all_build_output_log_rows = []
      @build_change_observer_blocks = []
      @github_service = github_service

      @current_build = prepare_build_object(trigger: trigger)
      # This build needs to be saved during initialization because RemoteRunner.start
      # is called by a TaskQueue and could potentially happen after the BuildController tries to
      # fetch this build.
      save_build_status_locally!

      @artifacts_path = Dir.mktmpdir

      fastlane_log_path = File.join(@artifacts_path, "fastlane.log")
      @fastlane_log = Logger.new(fastlane_log_path)
      @current_build.artifacts << Artifact.new(
        type: "fastlane.log",
        reference: fastlane_log_path,
        provider: @project.artifact_provider
      )

      @build_state = MicroMachine.new(:PENDING).tap do |fsm|
        fsm.when(:RUNNING,   PENDING:   :RUNNING)
        fsm.when(:REJECTED,  PENDING:   :REJECTED)
        fsm.when(:FINISHING, RUNNING:   :FINISHING)
        fsm.when(:SUCCEEDED, FINISHING: :SUCCEEDED)
        fsm.when(:FAILED,    RUNNING:   :FAILED)
        fsm.when(:BROKEN,    PENDING:   :BROKEN,
                             RUNNING:   :BROKEN,
                             FINISHING: :BROKEN)
      end
    end

    # Add a listener to get real time updates on new rows (see `new_row`)
    # This is used for the socket connection to the user's browser
    def add_build_change_listener(block)
      @build_change_observer_blocks << block
    end

    def start
      env = environment_variables_for_worker

      start_time = Time.now.utc
      begin
        responses = Agent::Client.new("localhost").request_run_fastlane(
          "bundle", "exec", "fastlane", project.platform, project.lane, env: env
        )
        responses.each do |response|
          validate_agent_response(response: response)
          process_agent_response(response: response)
        end
      rescue StandardError => exception
        emit_error_response(
          FastlaneCI::Proto::InvocationResponse::Error.new(
            description: exception.message,
            stacktrace: exception.backtrace.join("\n")
          )
        )
        emit_new_row(
          type: :ERROR,
          message: "Please make sure that the build agent is running!",
          time: Time.now
        )
      end
      emit_new_row(type: :last_message, message: nil, time: Time.now)

      current_build.duration = Time.now.utc - start_time
      if @build_state.state == :SUCCEEDED
        current_build.status = :success
        current_build.description = "All green"
        logger.info("fastlane run complete")
      else
        current_build.status = :failure
      end

      @current_build.artifacts.each do |artifact|
        project.artifact_provider.store!(artifact: artifact, build: current_build, project: project)
      end

      save_build_status!
      Services.build_runner_service.remove_build_runner(build_runner: self)
      return @build_state.state == :SUCCEEDED
    end

    def validate_agent_response(response:)
      if @build_state.state == :PENDING && !response.state
        raise "First InvocationResponse should change the state from :PENDING"
      end
      if response.state != :PENDING
        unless @build_state.trigger?(response.state)
          raise "Unexpected state change #{@build_state.state} -> #{response.state}"
        end
      elsif @build_state.state == :RUNNING && !response.log
        raise "Expecting InvocationResponses containing log lines while :RUNNING"
      elsif (@build_state.state == :BROKEN || @build_state.state == :REJECTED) && !response.error
        raise "Expecting InvocationResponses containing the error details after :BROKEN or :REJECTED"
      elsif @build_state.state == :FINISHING && !response.artifact
        raise "Expecting InvocationResponses containing artifacts while :FINISHING"
      elsif @build_state.state == :SUCCEEDED || @build_state.state == :FAILED
        raise "No further InvocationResponse messages expected after :SUCCEEDED or :FAILED"
      end
    end

    def process_agent_response(response:)
      if response.state != :PENDING
        @build_state.trigger(response.state)
      else
        case @build_state.state
        when :REJECTED
          # Agent is busy. How do we handle this?
          emit_error_response(response.error)
        when :RUNNING
          emit_new_row(
            type: response.log.level,
            message: response.log.message,
            time: Time.now
          )
        when :FINISHING
          artifact_path = File.join(@artifacts_path, response.artifact.filename)
          artifact = current_build.artifacts.find { |a| a.reference == artifact_path }
          unless artifact
            current_build.artifacts << Artifact.new(
              type: response.artifact.filename,
              reference: artifact_path,
              provider: @project.artifact_provider
            )
          end
          File.open(artifact_path, "a") { |f| f.write(response.artifact.chunk) }
        when :BROKEN
          emit_error_response(response.error)
        end
      end
    end

    # Handle a new incoming row (log), and alert every stakeholder who is interested
    def emit_new_row(type:, message:, time:)
      logger.debug(message) unless message.to_s.empty?

      row = BuildRunnerOutputRow.new(type: type, message: message, time: time)

      # Report back the row
      # 1)Store in the history of logs for this RemoteRunner (used to access half-built builds)
      all_build_output_log_rows << row

      # 2) Report back to all listeners, usually socket connections
      build_change_observer_blocks.each do |block|
        block.row_received(row)
      end

      # 3) update the fastlane.log artifact
      # TODO: respect the type of the log.
      @fastlane_log.debug(message)
    end

    def emit_error_response(error)
      error_message = error.description.to_s
      unless error.file.to_s.empty?
        error_message += "\n#{error.file}"
        error_message += " #{error.line_number}" if error.line_number
      end
      error_message += "\n#{error.stacktrace}" unless error.stacktrace.to_s.empty?
      error_message += "\nExitCode: #{error.exit_status}" if error.exit_status
      error_message.split("\n").each do |message|
        emit_new_row(type: :ERROR, message: message, time: Time.now)
      end
    end

    def prepare_build_object(trigger:)
      # TODO: move this into the service
      builds = Services.build_service.list_builds(project: project)

      if builds.count > 0
        new_build_number = builds.max_by(&:number).number + 1
      else
        new_build_number = 1 # We start with build number 1
      end

      FastlaneCI::Build.new(
        project: project,
        number: new_build_number,
        status: :pending,
        # Ensure we're using UTC because your server might have a different timezone.
        # While this isn't neccesary since timestamps are already UTC, it's good to message it here.
        # so that utc stuff is discoverable
        timestamp: Time.now.utc,
        duration: -1,
        trigger: trigger.type,
        lane: project.lane,
        platform: project.platform,
        git_fork_config: git_fork_config,
        # The versions of the build tools are set later one, after the repo was checked out
        # and we can read files like the `xcode-version` file
        build_tools: {}
      )
    end

    def environment_variables_for_worker
      # Set the CI specific Environment variables first

      # We try to follow the existing formats
      # https://wiki.jenkins.io/display/JENKINS/Building+a+software+project
      env_mapping = {
        BUILD_NUMBER: current_build.number,
        JOB_NAME: project.project_name,
        WORKSPACE: project.local_repo_path,
        GIT_URL: git_fork_config.clone_url,
        GIT_SHA: current_build.sha,
        BUILD_URL: "https://fastlane.ci", # TODO: actually build the URL, we don't know our own host, right?
        CI_NAME: "fastlane.ci",
        CI: true,
        FASTLANE_SKIP_DOCS: true
      }

      if git_fork_config.branch.to_s.length > 0
        env_mapping[:GIT_BRANCH] = git_fork_config.branch.to_s # TODO: does this work?
      else
        env_mapping[:GIT_BRANCH] = "master" # TODO: use actual default branch?
      end

      # We need to duplicate some ENV variables
      env_mapping[:CI_BUILD_NUMBER] = env_mapping[:BUILD_NUMBER]
      env_mapping[:CI_BUILD_URL] = env_mapping[:BUILD_URL]
      env_mapping[:CI_BRANCH] = env_mapping[:GIT_BRANCH]
      # env_mapping[:CI_PULL_REQUEST] = nil # TODO: do we have the PR information here?

      # Now that we have the CI specific ENV variables, let's go through the ENV variables
      # the user defined in their configuration
      Services.environment_variable_service.environment_variables.each do |environment_variable|
        if env_mapping.key?(environment_variable.key.to_sym)
          # TODO: this is probably large enough of an issue to use the fastlane.ci
          #       notification system to show an error to the user
          logger.error("Overwriting CI specific environment variable of key #{environment_variable.key} - " \
            "this is not recommended")
        end
        env_mapping[environment_variable.key.to_sym] = environment_variable.value
      end

      # Now set the project specific environment variables
      project.environment_variables.each do |environment_variable|
        if env_mapping.key?(environment_variable.key.to_sym)
          # TODO: similar to above: better error handling, depending on what variable gets overwritten
          #       this might be a big deal
          logger.error("Overwriting CI specific environment variable of key #{environment_variable.key}")
        end
        env_mapping[environment_variable.key.to_sym] = environment_variable.value
      end

      # Here we'll set the branch specific environment variables once this is implemented
      # This might not be top priority for a v1

      return env_mapping.map { |k, v| [k.to_s, v.to_s] }.to_h

      # TODO: to add potentially
      # - BUILD_ID
      # - BUILD_TAG
    end

    # Responsible for updating the build status in our local config
    # and on GitHub
    def save_build_status!
      # TODO: update so that we can strip out the SHAs that should never be attempted to be rebuilt
      save_build_status_locally!
      save_build_status_source!
    end

    def save_build_status_locally!
      # Create or update the local build file in the config directory
      Services.build_service.add_build!(
        project: project,
        build: current_build
      )

      # Commit & Push the changes to git remote
      FastlaneCI::Services.project_service.git_repo.commit_changes!

      # TODO: disabled for now so that while we developer we don't keep pushing to remote ci-config repo
      # FastlaneCI::Services.project_service.push_configuration_repo_changes!
    rescue StandardError => ex
      logger.error("Error setting the build status as part of the config repo")
      logger.error(ex)
      # If setting the build status inside the git repo fails
      # this is actually a big deal, and we can't proceed.
      # For setting the build status, if that fails, it's fine
      # as the source of truth is the git repo
      raise ex
    end

    # Let GitHub know about the current state of the build
    # Using a `rescue` block here is important
    # As the build is still green, even though we couldn't set the GH status
    def save_build_status_source!
      status_context = project.project_name

      build_path = FastlaneCI::BuildController.build_url(project_id: project.id, build_number: current_build.number)
      build_url = FastlaneCI.dot_keys.ci_base_url + build_path
      github_service.set_build_status!(
        repo: project.repo_config.git_url,
        sha: current_build.sha,
        state: current_build.status,
        target_url: build_url,
        status_context: status_context,
        description: current_build.description
      )
    rescue StandardError => ex
      logger.error("Error setting the build status on remote service")
      logger.error(ex)
    end
  end
end
