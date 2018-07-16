require_relative "../../shared/models/artifact"
require_relative "./build_runner_output_row"

# ideally we'd have a nicer way to inject this
require_relative "../../features/build/build_controller"

module FastlaneCI
  # Class that represents a BuildRunner, used
  # to run tests for a given commit sha
  #
  # Responsible for
  # - Run the build (e.g. fastlane via FastlaneBuildRunner) and check its return status
  # - Raise an exception if build fails, with information that can be handled by `TestRunnerService`
  # - Reporting back a list of artifacts  to `TestRunnerService`
  # - Measures the time of a `TestRunner`'s execution
  # - Stores the `Build` information in version control and triggers the report of the build status on GitHub
  # - Offer a way to subscribe to new lines being added to the output (e.g. to stream them to the user's browser)
  #
  class BuildRunner
    include FastlaneCI::Logging

    # Reference to the FastlaneCI::Project of this particular build run
    attr_reader :project

    # The code hosting service we want to report the status back to
    attr_reader :code_hosting_service

    # A reference to FastlaneCI::Build
    attr_accessor :current_build

    # The commit sha we want to run the build for
    attr_reader :sha

    # The local GitRepo we will be using
    attr_reader :repo

    # In case we need to fork, we can configure the git repo
    attr_reader :git_fork_config

    # All lines that were generated so far, this might not be a complete run
    # This is an array of hashes
    attr_accessor :all_build_output_log_rows

    # All build change observers that are listening to changes for this build
    attr_accessor :build_change_listeners

    # Work queue where builds should be run
    attr_reader :work_queue

    # Array of env variables that were set, that we need to unset after the run
    attr_accessor :environment_variables_set

    # Folder where the code will be checked out to, and where the build will happen
    attr_reader :local_build_folder

    def initialize(
      project:,
      sha:,
      github_service:,
      notification_service:,
      work_queue:,
      trigger:,
      git_fork_config:,
      local_build_folder: nil
    )
      if trigger.nil?
        raise "No trigger provided, this is probably caused by a build being triggered, " \
              "but then the project not having this particular build trigger associated"
      end

      if git_fork_config.nil?
        raise "No `git_fork_config` provided when creating a new `BuildRunner` object. A `git_fork_config`" \
              " is required to have the necessary information for historic builds to re-run a build"
      end

      # Setting the variables directly (only having `attr_reader`) as they're immutable
      # Once you define a FastlaneBuildRunner, you shouldn't be able to modify them
      @project = project
      @sha = sha
      @git_fork_config = git_fork_config
      @local_build_folder = local_build_folder

      self.all_build_output_log_rows = []
      self.build_change_listeners = []

      # TODO: provider credential should determine what exact CodeHostingService gets instantiated
      @code_hosting_service = github_service

      @work_queue = work_queue

      prepare_build_object(trigger: trigger)

      local_folder = @local_build_folder || File.join(project.local_repo_path, "builds", sha)
      @repo = GitRepo.new(
        git_config: project.repo_config,
        provider_credential: github_service.provider_credential,
        local_folder: local_folder,
        notification_service: notification_service,
        async_start: false
      )
    end

    # Access the build number of that specific BuildRunner
    def current_build_number
      return current_build.number
    end

    # Use this method for additional setup for subclasses
    # This method could have any number of additional parameters
    # that allow you to customize the runner
    # This method is called after `.new` was called from outside of BuildRunner
    def setup
      not_implemented(__method__)
    end

    def fail_build!(start_time:)
      duration = Time.now - start_time
      current_build.duration = duration
      current_build.status = :failure
      save_build_status!
    end

    def run_completed_ensure
      # Make sure to notify the listeners that the build is over
      new_row(
        FastlaneCI::BuildRunnerOutputRow.new(
          type: :last_message,
          message: nil,
          time: Time.now
        )
      )
      # Remove ourselves from the list of active build runners
      # to let the garbage collector do its thing
      Services.build_runner_service.remove_build_runner(build_runner: self)
    end

    def complete_run(start_time:, artifact_paths: [])
      artifacts = artifact_paths.map do |artifact|
        Artifact.new(
          type: artifact[:type],
          reference: artifact[:path],
          provider: project.artifact_provider
        )
      end.map do |artifact|
        project.artifact_provider.store!(artifact: artifact, build: current_build, project: project)
      end

      current_build.artifacts = artifacts

      duration = Time.now - start_time
      current_build.duration = duration

      # Status is set on the `current_build` object by the subclass
      save_build_status!
    rescue StandardError => ex
      logger.error(ex)
      fail_build!(start_time: start_time)
    ensure
      run_completed_ensure
    end

    def checkout_sha(&completion_block)
      pull_before_checkout_success = true

      if git_fork_config
        pull_before_checkout_success = repo.switch_to_fork(
          git_fork_config: git_fork_config,
          local_branch_prefex: git_fork_config.branch.to_s,
          use_global_git_mutex: false
        )
      else
        logger.debug("Pulling `master` in checkout_sha")
        repo.pull
      end

      unless pull_before_checkout_success
        logger.debug("Unable to pull before checking out #{sha} from #{project.project_name}, attempting checkout")
      end

      logger.debug("Checking out commit #{sha} from #{project.project_name}")
      repo.checkout_commit(sha: sha, completion_block: completion_block)
    end

    def pre_run_action(&completion_block)
      logger.debug("Running pre_run_action in checkout_sha")

      checkout_sha do |checkout_success|
        if checkout_success
          if setup_tooling_environment? # see comment for `#setup_tooling_environment?` method
            setup_build_specific_environment_variables
            completion_block.call(checkout_success)
          end
        else
          # TODO: this could be a notification specifically for user interaction
          logger.debug("Unable to launch build runner because we were unable to checkout the required sha: #{sha}")
          completion_block.call(checkout_success)
        end
      end
    end

    # Implement this method in sub classes to prepare necessary tooling
    # like Xcode or Android studio, to be able to successfully run a build
    # @return [Boolean] Return `false` if the build trigger some longer process
    #         e.g. installing a new development environment. This will not call
    #         the completion block and interrupt running the give build.
    #         It's critical that the `setup_tooling_environment?` method
    #         added the same build runner onto the work queue again
    #         Check out the `fastlane_build_runner` implementation for more details
    def setup_tooling_environment?
      not_implemented(__method__)
    end

    def setup_build_specific_environment_variables
      @environment_variables_set = []

      # Set the CI specific Environment variables first
      build_url = File.join(
        Services.dot_keys_variable_service.keys.ci_base_url,
        "projects",
        project.id,
        "builds",
        current_build_number.to_s
      )

      # We try to follow the existing formats
      # https://wiki.jenkins.io/display/JENKINS/Building+a+software+project
      env_mapping = {
        BUILD_NUMBER: current_build_number,
        JOB_NAME: project.project_name,
        WORKSPACE: project.local_repo_path,
        GIT_URL: repo.git_config.git_url,
        GIT_SHA: current_build.sha,
        BUILD_URL: build_url,
        BUILD_ID: current_build_number.to_s,
        CI_NAME: "fastlane.ci",
        FASTLANE_CI: true,
        CI: true
      }

      if git_fork_config.branch.to_s.length > 0
        env_mapping[:GIT_BRANCH] = git_fork_config.branch.to_s
      else
        env_mapping[:GIT_BRANCH] = "master"
      end

      # We need to duplicate some ENV variables
      env_mapping[:CI_BUILD_NUMBER] = env_mapping[:BUILD_NUMBER]
      env_mapping[:CI_BUILD_URL] = env_mapping[:BUILD_URL]
      env_mapping[:CI_BRANCH] = env_mapping[:GIT_BRANCH]
      # env_mapping[:CI_PULL_REQUEST] = nil # It seems like we don't have PR information here

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

      # Finally, set all the ENV variables for the given build
      env_mapping.each do |key, value|
        set_build_specific_env_variable(key: key, value: value)
      end

      # TODO: to add potentially
      # - BUILD_ID
      # - BUILD_TAG
    end

    def set_build_specific_env_variable(key:, value:)
      if ENV[key.to_s].to_s.strip.length > 0
        logger.info("Environment variable `#{key}` is already set, overwriting now")
      end
      ENV[key.to_s] = value.to_s

      environment_variables_set << key
    end

    def post_run_action
      logger.debug("Finished running #{project.project_name} for #{sha}")

      unset_build_specific_environment_variables
    end

    def unset_build_specific_environment_variables
      return if environment_variables_set.nil?
      environment_variables_set.each do |key|
        ENV.delete(key.to_s)
      end
      @environment_variables_set = nil
    end

    def run_action(start_time:)
      run(
        new_line_block: proc do |current_row|
          new_row(current_row)
        end,
        completion_block: proc do |artifact_paths|
          complete_run(start_time: start_time, artifact_paths: artifact_paths)
        end
      )
    end

    # Starts the build, incrementing the build number from the number of builds
    # for a given project
    #
    # @return [nil]
    def start
      logger.debug("Starting build runner #{self.class} for #{project.project_name} #{project.id} sha: #{sha} now...")
      start_time = Time.now

      work_block = proc do
        pre_run_action do |pre_run_success|
          if pre_run_success
            run_action(start_time: start_time)
          else
            # Don't even try to build, just fail it now
            fail_build!(start_time: start_time)

            # Since we're short circuiting, we need to call the ensure block by hand here
            run_completed_ensure
          end
        end
      end

      post_run_block = proc { post_run_action }

      # If we have a work_queue, execute on that
      if work_queue
        runner_task = TaskQueue::Task.new(work_block: work_block, ensure_block: post_run_block)
        work_queue.add_task_async(task: runner_task)
      else
        # No work queue? Just call the block then
        logger.debug("Not using a workqueue for build runner #{self.class}, this is probably a bug")

        begin
          work_block.call
        rescue StandardError => ex
          logger.error(ex)
        ensure
          # this is already called in an ensure block if we're using a workqueue to execute it
          # so no need to wrap the task queue's version of `post_run_block`
          post_run_block.call
        end
      end
    end

    # @return [Array[String]] of references for the different artifacts created by the runner.
    # TODO: are these Artifact objects or paths?
    # Important: The `run` method must always call completion_block, even when there is an exception
    def run(new_line_block:, completion_block:)
      not_implemented(__method__)
    end

    # Responsible for updating the build status in our local config
    # and on GitHub
    def save_build_status!
      # TODO: update so that we can strip out the SHAs that should never be attempted to be rebuilt
      save_build_status_locally!
      save_build_status_source!
    end

    # Handle a new incoming row, and alert every stakeholder who is interested
    def new_row(row)
      logger.debug(row.message) if row.message.to_s.length > 0

      # Report back the row
      # 1) Store it in the history of logs (used to access half-built builds)
      all_build_output_log_rows << row

      # 2) Report back to all listeners, usually socket connections
      listeners_done_listening = []
      build_change_listeners.each do |current_listener|
        if current_listener.done_listening?
          listeners_done_listening << current_listener
          next
        end

        current_listener.row_received(row)
      end

      # remove any listeners that are done listening
      self.build_change_listeners -= listeners_done_listening
    end

    # Add a listener to get real time updates on new rows (see `new_row`)
    # This is used for the socket connection to the user's browser
    def add_build_change_listener(listener)
      build_change_listeners << listener
    end

    def prepare_build_object(trigger:)
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
        git_fork_config: git_fork_config
      )
      save_build_status!
    end

    private

    def save_build_status_locally!
      # Create local build file in the config directory
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

      build_path = FastlaneCI::BuildJSONController.build_url(project_id: project.id, build_number: current_build.number)
      build_url = FastlaneCI.dot_keys.ci_base_url + build_path
      code_hosting_service.set_build_status!(
        repo: project.repo_config.git_url,
        sha: sha,
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

require_relative "./fastlane_build_runner"
