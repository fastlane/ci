require_relative "../../shared/models/artifact"
require_relative "./build_runner_output_row"

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

    # All blocks listening to changes for this build
    attr_accessor :build_change_observer_blocks

    # Work queue where builds should be run
    attr_reader :work_queue

    # Array of env variables that were set, that we need to unset after the run
    attr_accessor :environment_variables_set

    def initialize(project:, sha:, github_service:, work_queue:, trigger:, git_fork_config: nil)
      if trigger.nil?
        raise "No trigger provided, this is probably caused by a build being triggered, but then the project not having this particular build trigger associated"
      end

      # Setting the variables directly (only having `attr_reader`) as they're immutable
      # Once you define a FastlaneBuildRunner, you shouldn't be able to modify them
      @project = project
      @sha = sha
      @git_fork_config = git_fork_config

      self.all_build_output_log_rows = []
      self.build_change_observer_blocks = []

      # TODO: provider credential should determine what exact CodeHostingService gets instantiated
      @code_hosting_service = github_service

      @work_queue = work_queue

      prepare_build_object(trigger: trigger)

      @repo = GitRepo.new(
        git_config: project.repo_config,
        provider_credential: github_service.provider_credential,
        local_folder: File.join(project.local_repo_path, "builds", sha),
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
    def setup
      not_implemented(__method__)
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
      duration = Time.now - start_time
      current_build.duration = duration
      current_build.status = :failure # TODO: also handle failure
      save_build_status!
    end

    def checkout_sha
      if git_fork_config
        repo.switch_to_fork(clone_url: git_fork_config.clone_url,
                               branch: git_fork_config.branch,
                                  sha: git_fork_config.current_sha,
                    local_branch_name: "#{git_fork_config.branch}_local_fork",
                 use_global_git_mutex: false)
      else
        repo.reset_hard!
        logger.debug("Pulling `master` in checkout_sha")
        repo.pull
      end

      logger.debug("Checking out commit #{sha} from #{project.project_name}")
      repo.checkout_commit(sha: sha)
    end

    def pre_run_action
      logger.debug("Running pre_run_action in checkout_sha")
      checkout_sha
      setup_build_specific_environment_variables
    end

    def setup_build_specific_environment_variables
      self.environment_variables_set = []

      # We try to follow the existing formats
      # https://wiki.jenkins.io/display/JENKINS/Building+a+software+project
      env_mapping = {
        BUILD_NUMBER: current_build_number,
        JOB_NAME: project.project_name,
        WORKSPACE: project.local_repo_path,
        GIT_URL: repo.git_config.git_url,
        GIT_SHA: current_build.sha,
        BUILD_URL: "https://fastlane.ci", # TODO: actually build the URL, we don't know our own host, right?
        CI_NAME: "fastlane.ci",
        CI: true
      }

      if git_fork_config && git_fork_config.branch.to_s.length > 0
        env_mapping[:GIT_BRANCH] = git_fork_config.branch # TODO: does this work?
      else
        env_mapping[:GIT_BRANCH] = "master" # TODO: use actual default branch?
      end

      # We need to duplicate some ENV variables
      env_mapping[:CI_BUILD_NUMBER] = env_mapping[:BUILD_NUMBER]
      env_mapping[:CI_BUILD_URL] = env_mapping[:BUILD_URL]
      env_mapping[:CI_BRANCH] = env_mapping[:GIT_BRANCH]
      # env_mapping[:CI_PULL_REQUEST] = nil # TODO: do we have the PR information here?

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

    def reset_repo_state
      # When we're done, clean up by resetting
      repo.reset_hard!
    end

    def post_run_action
      logger.debug("Finished running #{project.project_name} for #{sha}")
      reset_repo_state

      unset_build_specific_environment_variables
    end

    def unset_build_specific_environment_variables
      environment_variables_set.each do |key|
        ENV.delete(key.to_s)
      end
      self.environment_variables_set = nil
    end

    # Starts the build, incrementing the build number from the number of builds
    # for a given project
    #
    # @return [nil]
    def start
      logger.debug("Starting build runner #{self.class} for #{project.project_name} #{project.id} sha: #{sha} now...")
      start_time = Time.now
      artifact_handler_block = proc { |artifact_paths| complete_run(start_time: start_time, artifact_paths: artifact_paths) }

      work_block = proc {
        pre_run_action
        run(completion_block: artifact_handler_block) do |current_row|
          new_row(current_row)
        end
      }

      post_run_block = proc {
        post_run_action
      }

      # If we have a work_queue, execute on that
      if work_queue
        runner_task = TaskQueue::Task.new(work_block: work_block, ensure_block: post_run_block)
        work_queue.add_task_async(task: runner_task)
      else
        # No work queue? Just call the block then
        logger.debug("Not using a workqueue for build runner #{self.class}, this is probably a bug")
        work_block.call
        post_run_block.call
      end
    end

    # @return [Array[String]] of references for the different artifacts created by the runner.
    # TODO: are these Artifact objects or paths?
    def run(*args)
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
      build_change_observer_blocks.each do |current_block|
        current_block.call(row)
      end
    end

    # Add a listener to get real time updates on new rows (see `new_row`)
    # This is used for the socket connection to the user's browser
    def add_listener(block)
      build_change_observer_blocks << block
    end

    def prepare_build_object(trigger:)
      builds = Services.build_service.list_builds(project: project)

      if builds.count > 0
        new_build_number = builds.sort_by(&:number).last.number + 1
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
        sha: sha,
        trigger: trigger.type
      )
      save_build_status!
    end

    private

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

      code_hosting_service.set_build_status!(
        repo: project.repo_config.git_url,
        sha: sha,
        state: current_build.status,
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
