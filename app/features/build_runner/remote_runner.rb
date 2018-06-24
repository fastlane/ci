require_relative "../../../agent/client"

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
    # TODO: add state machine-type impl.

    def initialize(project:, git_fork_config:, trigger:, github_service:)
      @project = project
      @git_fork_config = git_fork_config

      prepare_build_object(trigger: trigger)
      @client = Agent::Client.new("localhost")

      @all_build_output_log_rows = []
      @build_change_observer_blocks = []
      @github_service = github_service
    end

    # Add a listener to get real time updates on new rows (see `new_row`)
    # This is used for the socket connection to the user's browser
    def add_build_change_listener(block)
      @build_change_observer_blocks << block
    end

    def start
      env = environment_variables_for_worker(
        current_build: current_build,
        project: project,
        git_fork_config: git_fork_config
      )

      success = true
      start_time = Time.now.utc

      responses = @client.request_run_fastlane("fastlane", project.platform, project.lane, env: env)
      responses.each do |response|
        # TODO: handle all types of responses, included the state ones
        if response.log
          did_receive_new_row(
            BuildRunnerOutputRow.new(
              type: :message,
              message: response.log.message,
              time: Time.now
            )
          )
        elsif response.error
          did_receive_new_row(
            BuildRunnerOutputRow.new(
              type: :build_error,
              message: response.error.description,
              time: Time.now
            )
          )
        end
        success = false if response.error
      end

      current_build.duration = Time.now.utc - start_time

      if success
        current_build.status = :success
        current_build.description = "All green"
        logger.info("fastlane run complete")
      else
        current_build.status = :failure
      end

      did_receive_new_row(
        BuildRunnerOutputRow.new(
          type: :last_message,
          message: nil,
          time: Time.now
        )
      )

      save_build_status!
      Services.build_runner_service.remove_build_runner(build_runner: self)
      return success
    end

    # Handle a new incoming row (log), and alert every stakeholder who is interested
    def did_receive_new_row(row)
      logger.debug(row.message) if row.message.to_s.length > 0

      # Report back the row
      # 1)Store in the history of logs for this RemoteRunner (used to access half-built builds)
      all_build_output_log_rows << row

      # 2) Report back to all listeners, usually socket connections
      build_change_observer_blocks.each do |block|
        block.row_received(row)
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

      @current_build = FastlaneCI::Build.new(
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
      # This build needs to be saved during initialization because RemoteRunner.start
      # is called by a TaskQueue and could potentially happen after the BuildController tries to
      # fetch this build.
      save_build_status!
    end

    def environment_variables_for_worker(current_build:, project:, git_fork_config:)
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
        FASTLANE_SKIP_DOCS: true,
        FASTLANE_CI_ARTIFACTS: "artifacts"
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

    def fail_build!(start_time:)
      save_build_status!
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
