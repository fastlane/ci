module FastlaneCI
  # Responsible for the life cycle of running tests as part of fastlane.ci
  # In particular this takes care of all the overhead, like measuring the time and storing & reporting
  # the build status
  # - TestRunnerService owns a TestRunner
  # - TestRunnerService is alive until it's finished running
  # - TestRunnerService is created on the fly, either when "resuming" a build, or when a new build is triggered by a project trigger
  # - TestRunner only runs tests. Stays alive as long as the TestRunnerService
  # TODO: move github specific stuff out into GitHubService (GitHubService right now)
  # TODO: maybe rename this to GitHubTestRunnerService
  class TestRunnerService
    class << self
      # TODO: move all the things below somewhere else
      # we need to hold all test runner services, to not destroy them with the garbage collector
      # and also to access them as part of our middle ware
      # it probably makes sense to have a single TestRunnerService, that holds multiple TestRunners instead
      def test_runner_services
        @test_runner_services ||= []
      end
    end

    include FastlaneCI::Logging

    attr_accessor :project
    attr_accessor :build_service
    attr_accessor :code_hosting_service
    attr_accessor :current_build
    attr_accessor :sha

    # All lines that were generated so far, this might not be a complete run
    # This is an array of hashes
    # TODO: have a class representing a Row (has to offer dynamic values though, as we might have non fastlane runners in the future)
    attr_accessor :all_build_output_log_lines

    # All blocks listening to changes for this build
    attr_accessor :build_change_observer_blocks

    # The TestRunner object that is responsible for running the actual tests
    attr_accessor :test_runner

    def initialize(project: nil, sha: nil, github_service: nil, test_runner: nil)
      self.project = project
      self.sha = sha

      self.build_service = FastlaneCI::Services.build_service

      # TODO: provider credential should determine what exact CodeHostingService gets instantiated
      self.code_hosting_service = github_service

      self.all_build_output_log_lines = []
      self.build_change_observer_blocks = []

      self.test_runner = FastlaneTestRunner.new(
        platform: "ios", # nil, # TODO: is the platform gonna be part of the `project.lane`? Probably yes
        lane: "beta", # project.lane,
        parameters: nil
      )

      self.prepare_build_object

      # Add yourself to the list of active workers so we can stream the output to the user
      # this might be nil, while the server still starts
      self.class.test_runner_services << self
    end

    def add_listener(block)
      self.build_change_observer_blocks << block
    end

    # Handle a new incoming row, and alert every stakeholder who is interested
    def new_row(row)
      logger.debug(row["message"])

      # Report back the row
      # 1) Store it in the history of logs (used to access half-built builds)
      all_build_output_log_lines << row

      # 2) Report back to all listeners, usually socket connections
      self.build_change_observer_blocks.each do |current_block|
        current_block.call(row)
      end
    end

    def prepare_build_object
      builds = build_service.list_builds(project: self.project)

      if builds.count > 0
        new_build_number = builds.sort_by(&:number).last.number + 1
      else
        new_build_number = 1 # do we start with 1?
      end

      self.current_build = FastlaneCI::Build.new(
        project: self.project,
        number: new_build_number,
        status: :pending,
        timestamp: Time.now,
        duration: -1,
        sha: self.sha
      )
      update_build_status!
    end

    # Runs a new build, incrementing the build number from the number of builds
    # for a given project
    #
    # @return [nil]
    def run
      start_time = Time.now

      logger.debug("Running runner now")

      test_runner.run do |current_row|
        new_row(current_row)
      end

      duration = Time.now - start_time

      current_build.duration = duration
      current_build.status = :success

      self.update_build_status!
    rescue StandardError => ex
      # TODO: better error handling, don't catch all Exception
      puts(ex)
      duration = Time.now - start_time
      current_build.duration = duration
      current_build.status = :failure # TODO: also handle failure
      self.update_build_status!
    end

    # Re-runs a build passed in, does not modify the build number
    #
    # @param  [Build] build
    # @return [nil]
    def rerun(build = nil)
      start_time = Time.now

      self.current_build = build
      update_build_status!

      logger.debug("Running runner now")
      test_runner.run do |row|
        new_row(row)
      end

      duration = Time.now - start_time

      current_build.duration = duration
      current_build.status = :success

      self.update_build_status!
    rescue StandardError => ex
      # TODO: better error handling, don't catch all Exception
      puts(ex)
      duration = Time.now - start_time
      current_build.duration = duration
      current_build.status = :failure # TODO: also handle failure
      self.update_build_status!
    end

    # Responsible for updating the build status in our local config
    # and on GitHub
    def update_build_status!
      update_build_status_locally!
      update_build_status_source!
    end

    private

    def update_build_status_locally!
      # Create or update the local build file in the config directory
      build_service.add_build!(
        project: self.project,
        build: self.current_build
      )

      # Commit & Push the changes to git remote
      FastlaneCI::Services.project_service.git_repo.commit_changes!
    rescue StandardError => ex
      logger.error("Error setting the build status as part of the config repo")
      logger.error(ex.to_s)
      logger.error(ex.backtrace.join("\n"))
      # If setting the build status inside the git repo fails
      # this is actually a big deal, and we can't proceed.
      # For setting the build status, if that fails, it's fine
      # as the source of truth is the git repo
      raise ex
    end

    # Let GitHub know about the current state of the build
    # Using a `rescue` block here is important
    # As the build is still green, even though we couldn't set the GH status
    def update_build_status_source!
      self.code_hosting_service.set_build_status!(
        repo: self.project.repo_config.git_url,
        sha: self.sha,
        state: self.current_build.status,
        target_url: nil
      )
    rescue StandardError => ex
      logger.error("Error setting the build status on remote service")
      logger.error(ex.to_s)
      logger.error(ex.backtrace.join("\n"))
    end
  end
end
