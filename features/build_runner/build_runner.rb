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
    attr_reader :current_build

    # The commit sha we want to run the build for
    attr_reader :sha

    # All lines that were generated so far, this might not be a complete run
    # This is an array of hashes
    # TODO: have a class representing a Row (has to offer dynamic values though, as we might have non fastlane runners in the future)
    attr_accessor :all_build_output_log_lines

    # All blocks listening to changes for this build
    attr_accessor :build_change_observer_blocks

    def initialize(project:, sha:, github_service:)
      # Setting the variables directly (only having `attr_reader`) as they're immutable
      # Once you define a FastlaneBuildRunner, you shouldn't be able to modify them
      @project = project
      @sha = sha

      self.all_build_output_log_lines = []
      self.build_change_observer_blocks = []

      # TODO: provider credential should determine what exact CodeHostingService gets instantiated
      @code_hosting_service = github_service

      self.prepare_build_object
    end

    # Access the build number of that specific BuildRunner
    def current_build_number
      return self.current_build.number
    end

    # Use this method for additional setup for subclasses
    # This method could have any number of additional parameters
    # that allow you to customize the runner
    def setup
      not_implemented(__method__)
    end

    # Starts the build, incrementing the build number from the number of builds
    # for a given project
    #
    # @return [nil]
    def start
      start_time = Time.now

      logger.debug("Starting build runner #{self.class} for #{self.project.project_name} #{self.project.id} now...")

      artifact_paths = self.run do |current_row|
        new_row(current_row)
      end

      artifacts = artifact_paths.map do |artifact|
        Artifact.new(
          type: artifact[:type],
          reference: artifact[:path],
          provider: self.project.artifact_provider
        )
      end.map do |artifact|
        self.project.artifact_provider.store!(artifact: artifact, build: self.current_build, project: self.project)
      end

      self.current_build.artifacts = artifacts

      duration = Time.now - start_time
      current_build.duration = duration

      # Status is set on the `current_build` object by the subclass
      self.save_build_status!
    rescue StandardError => ex
      # TODO: better error handling, don't catch all Exception
      logger.error(ex)
      duration = Time.now - start_time
      current_build.duration = duration
      current_build.status = :failure # TODO: also handle failure
      self.save_build_status!
    end

    # @return [Array[String]] of references for the different artifacts created by the runner.
    def run(*args)
      not_implemented(__method__)
    end

    # Responsible for updating the build status in our local config
    # and on GitHub
    def save_build_status!
      save_build_status_locally!
      save_build_status_source!
    end

    # Handle a new incoming row, and alert every stakeholder who is interested
    def new_row(row)
      logger.debug(row["message"]) if row["message"].to_s.length > 0

      # Report back the row
      # 1) Store it in the history of logs (used to access half-built builds)
      self.all_build_output_log_lines << row

      # 2) Report back to all listeners, usually socket connections
      self.build_change_observer_blocks.each do |current_block|
        current_block.call(row)
      end
    end

    # Add a listener to get real time updates on new rows (see `new_row`)
    # This is used for the socket connection to the user's browser
    def add_listener(block)
      self.build_change_observer_blocks << block
    end

    def prepare_build_object
      builds = Services.build_service.list_builds(project: self.project)

      if builds.count > 0
        new_build_number = builds.sort_by(&:number).last.number + 1
      else
        new_build_number = 1 # We start with build number 1
      end

      @current_build = FastlaneCI::Build.new(
        project: self.project,
        number: new_build_number,
        status: :pending,
        timestamp: Time.now,
        duration: -1,
        sha: self.sha
      )
      save_build_status!
    end

    private

    def save_build_status_locally!
      # Create or update the local build file in the config directory
      Services.build_service.add_build!(
        project: self.project,
        build: self.current_build
      )

      # Commit & Push the changes to git remote
      FastlaneCI::Services.project_service.git_repo.commit_changes!
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
      self.code_hosting_service.set_build_status!(
        repo: self.project.repo_config.git_url,
        sha: self.sha,
        state: self.current_build.status,
        status_context: self.project.project_name
      )
    rescue StandardError => ex
      logger.error("Error setting the build status on remote service")
      logger.error(ex)
    end
  end
end

require_relative "./fastlane_build_runner"
