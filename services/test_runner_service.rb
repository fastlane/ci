module FastlaneCI
  # Service that will interact with fastlane to run tests/lanes
  # TODO: move github specific stuff out into GitHubService (GitHubService right now)
  # TODO: maybe rename this to GitHubTestRunnerService
  class TestRunnerService
    include FastlaneCI::Logging

    attr_accessor :project
    attr_accessor :build_service
    attr_accessor :code_hosting_service
    attr_accessor :current_build
    attr_accessor :sha

    def initialize(project: nil, sha: nil, github_service: nil)
      self.project = project
      self.sha = sha

      self.build_service = FastlaneCI::Services.build_service

      # TODO: provider credential should determine what exact CodeHostingService gets instantiated
      self.code_hosting_service = github_service
    end

    def run
      start_time = Time.now
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

      # TODO: Replace with fastlane runner here
      command = "rubocop #{project.repo_config.local_repo_path}"
      logger.info("Running #{command}")

      cmd = TTY::Command.new
      cmd.run(command)

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
      FastlaneCI::Services.project_data_source.git_repo.commit_changes!
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
