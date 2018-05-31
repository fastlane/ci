require_relative "../../../agent/client"

module FastlaneCI
  class RemoteRunner
    include FastlaneCI::Logging

    # Reference to the FastlaneCI::Project of this particular build run
    attr_reader :project

    # In case we need to fork, we can configure the git repo
    attr_reader :git_fork_config

    # Access the FastlaneCI::Build of that specific Runner
    attr_reader :current_build

    def initialize(project:, git_fork_config:, trigger:)
      @project = project
      @git_fork_config = git_fork_config
      @client = Agent::Client.new("localhost")

      @current_build = prepare_build(project: project, git_fork_config: git_fork_config, trigger: trigger)

      # The versions of the build tools are set later one, after the repo was checked out
      # and we can read files like the `xcode-version` file
      @current_build.build_tools = {}

      @build_change_observer_blocks = []
    end

    # Add a listener to get real time updates on new rows (see `new_row`)
    # This is used for the socket connection to the user's browser
    def add_listener(block)
      @build_change_observer_blocks << block
    end

    #
    def sha
      git_fork_config.sha
    end


    def start
      #file = File.open("/tmp/fastlane-ci.log", "w")
      #file.sync = true
      success = true
      save_build_status_locally!
      env =  environment_variables_for_worker(current_build: current_build, project: project, git_fork_config: git_fork_config)

      logs = @client.request_spawn("rake", "fastlane[#{@project.platform} #{@project.lane}]", env: env)
      logs.each do |log|
        #file.write({message: log.message, level: log.level, status: log.status}.to_json)
        @build_change_observer_blocks.each do |block|
          custom_row = BuildRunnerOutputRow.new(
            type: "message",
            message: log.message,
            time: Time.now
          )
          block.call(custom_row)
          logger.info("sent a mesage to the observe")
        end

        if log.status != 0
         logger.error("WE HAVE AN ERROR!")
         success = false
        end
      end

      #file.close

      return success
    end

    def prepare_build(project:, git_fork_config:, trigger:)
      # TODO: move this into the service
      builds = Services.build_service.list_builds(project: project)

      if builds.count > 0
        new_build_number = builds.max_by(&:number).number + 1
      else
        new_build_number = 1 # We start with build number 1
      end

      return FastlaneCI::Build.new(
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
        CI: true
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

      return env_mapping.map {|k,v| [k.to_s, v.to_s]}.to_h

      # TODO: to add potentially
      # - BUILD_ID
      # - BUILD_TAG
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

  end
end
