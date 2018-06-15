require_relative "./fastlane_build_runner_helpers/fastlane_ci_output"
require_relative "./fastlane_build_runner_helpers/fastlane_log"
require_relative "./fastlane_build_runner_helpers/fastlane_output_to_html"
require_relative "./build_runner"
require_relative "../../shared/fastfile_finder"

require "tmpdir"
require "bundler"

module FastlaneCI
  # Represents the build runner responsible for loading and running
  # fastlane Fastfile configurations
  # - Loading up _fastlane_ and running a lane with it, checking the return status
  # - Take the artifacts from fastlane, and store them using the artifact related code of fastlane.ci
  #
  # TODO: run method *should* return an array of artifacts
  #
  class FastlaneBuildRunner < BuildRunner
    include FastlaneCI::Logging

    # Parameters for running fastlane
    attr_reader :platform
    attr_reader :lane
    attr_reader :parameters

    # @return [String] The path to the Xcode installation to use for this build
    attr_reader :xcode_path_to_use

    # Set additional values specific to the fastlane build runner
    # TODO: the parameters are not used/implemented yet, see https://github.com/fastlane/ci/issues/783
    def setup(parameters: nil)
      # Setting the variables directly (only having `attr_reader`) as they're immutable
      # Once you define a FastlaneBuildRunner, you shouldn't be able to modify them
      @platform = project.platform
      @lane = project.lane
      @parameters = parameters

      # Append additional metadata to the build for historic information
      current_build.lane = lane
      current_build.platform = platform
      current_build.parameters = self.parameters

      # The versions of the build tools are set later one, after the repo was checked out
      # and we can read files like the `xcode-version` file
      current_build.build_tools = {}

      # We want to store the lane, platform and parameters
      # that's why we call it here as well as implicitly in
      # `BuildRunner#prepare_build_object` with save_build_status!
      save_build_status_locally!
    end

    # completion_block is called with an array of artifacts
    def run(new_line_block:, completion_block:)
      if lane.nil?
        raise "Before calling `.run` on #{self}, you have to call `.setup` to finish preparing the BuildRunner"
      end

      artifacts_paths = [] # first thing we do, as we access it in the `ensure` block of this method
      require "fastlane"

      ci_output = FastlaneCI::FastlaneCIOutput.new(
        each_line_block: proc do |raw_row|
          new_line_block.call(convert_raw_row_to_object(raw_row))
        end
      )

      temporary_output_directory = Dir.mktmpdir
      verbose_log = FastlaneCI::FastlaneLog.new(
        file_path: File.join(temporary_output_directory, "fastlane.verbose.log"),
        severity: Logger::DEBUG
      )
      info_log = FastlaneCI::FastlaneLog.new(
        file_path: File.join(temporary_output_directory, "fastlane.log")
      )

      ci_output.add_output_listener!(verbose_log)
      ci_output.add_output_listener!(info_log)

      FastlaneCore::UI.ui_object = ci_output

      # this only takes a few ms the first time being called
      Fastlane.load_actions

      fast_file_path = FastlaneCI::FastfileFinder.find_fastfile_in_repo(repo: repo)

      if fast_file_path.nil? || !File.exist?(fast_file_path)
        # rubocop:disable Metrics/LineLength
        logger.info("unable to start fastlane run lane: #{lane} platform: #{platform}, params: #{parameters}, no Fastfile for commit")
        current_build.status = :missing_fastfile
        current_build.description = "We're unable to start fastlane run lane: #{lane} platform: #{platform}, params: #{parameters}, because no Fastfile existed at the time the commit was made"
        # rubocop:enable Metrics/LineLength
        return
      end

      FastlaneCore::Globals.verbose = true

      begin
        # TODO: I think we need to clear out the singleton values, such as lane context, and all that jazz
        # Execute the Fastfile here
        # rubocop:disable Metrics/LineLength
        logger.info("starting fastlane run lane: #{lane} platform: #{platform}, params: #{parameters} from #{fast_file_path}")
        # rubocop:enable Metrics/LineLength

        # TODO: the fast_file.runner should probably handle this
        logger.debug("Switching to #{repo.local_folder} to run `fastlane`")

        # Change over to the repo, inside the `fastlane` folder
        # This is critical to do
        # As only going into the checked out repo folder will cause the
        # fastlane code base to look for the Fastfile again, and with it
        # its configuration files, and with it, cd .. somewhere in the stack
        # causing the rest to not work
        # Using the code below, we ensure we're in the `./fastlane` or `./.fastlane`
        # folder, and all the following code works
        # This is needed to load other configuration files, and also find Xcode projects

        # This step is needed in case of the target Project's repo having its own gem
        # dependencies. As we don't isolate the build process by now, we have to inject
        # those dependencies into the CI system in order to work fine.
        # The first step is to make a snapshot of the current state of the CI's Gemfile and Gemfile.lock
        original_gemfile_contents = File.read(Bundler.default_gemfile)
        original_lockfile_contents = File.read(Bundler.default_lockfile)

        # We call the safe (because is synchronized) Bundler's `chdir` and
        # install all the dependencies, if any.
        Bundler::SharedHelpers.chdir(repo.local_folder) do
          ENV["FASTLANE_SKIP_DOCS"] = true.to_s

          gemfile_found = Dir[File.join(Dir.pwd, "**", "Gemfile")].any?
          if gemfile_found
            begin
              gemfile_dir = Dir[File.join(Dir.pwd, "**", "Gemfile")].first

              # In case the target repo has its own Gemfile, we parse its contents
              builder = Bundler::Dsl.new
              builder.eval_gemfile(gemfile_dir)

              # We already use local fastlane, so don't try to install it.
              project_dependencies = builder.dependencies.reject { |d| d.name == "fastlane" }

              # Inject all other dependencies that might be needed by the target.
              added = Bundler::Injector.inject(project_dependencies, {})
              if added.any?
                logger.info("Added to Gemfile:")
                logger.info(added.map do |d|
                  name = "'#{d.name}'"
                  requirement = ", '#{d.requirement}'"
                  group = ", :group => #{d.groups.inspect}" if d.groups != Array(:default)
                  source = ", :source => '#{d.source}'" unless d.source.nil?
                  %(gem #{name}#{requirement}#{group}#{source})
                end.join("\n"))
              end

              # Install the new Bundle and require all the new gems into the runtime.
              Bundler::Installer.install(Bundler.root, Bundler.definition)
              Bundler.require
            rescue Bundler::GemfileNotFound, Bundler::GemNotFound => ex
              logger.info(ex)
            rescue Gem::LoadError => ex
              logger.error(ex)
            rescue StandardError => ex
              logger.error(ex)
              logger.error(ex.backtrace)
            end
          end

          # Reset the Xcode version to the system default first
          Services.xcode_manager_service.reset_xcode_version!

          # Switch to the specified Xcode (if specified)
          if xcode_path_to_use.to_s.length > 0
            Services.xcode_manager_service.switch_xcode_version!(
              xcode_path: xcode_path_to_use.to_s # .to_s as it's a `PathName`
            )
          end

          # We always want to fetch the currently used Xcode version
          # and store it as part of the build metadata inside the `build_tools` attribute
          # to make builds reproducable
          # TODO: take the `build_tools` hash into account when hitting `re-run` on a given build
          current_build.build_tools[:xcode_version] = Services.xcode_manager_service.current_xcode_version.to_s

          begin
            # Run fastlane now
            Fastlane::LaneManager.cruise_lane(
              platform,
              lane,
              parameters,
              nil,
              fast_file_path
            )
          rescue StandardError => ex
            # TODO: refactor this to reduce duplicate code
            logger.debug("Setting build status to error from fastlane")
            current_build.status = :failure
            current_build.description = "Build failed"

            logger.error(ex)
            logger.error(ex.backtrace)

            new_line_block.call(convert_raw_row_to_object({
              type: "crash",
              message: ex.to_s,
              time: Time.now
            }))
            ci_output.output_listeners.each do |listener|
              listener.error(ex.to_s)
            end
            artifacts_paths = gather_build_artifact_paths(loggers: [verbose_log, info_log])

            return
          ensure
            Services.xcode_manager_service.reset_xcode_version! if xcode_path_to_use

            if gemfile_found
              # This is te step for recovering the pre-build dependency graph for the CI
              # The first step is to write the snapshot we made at the start of the build.
              File.write(Bundler.default_gemfile, original_gemfile_contents)
              File.write(Bundler.default_lockfile, original_lockfile_contents)
              # Our bundle runtime already has the build's gems installed and loaded, so
              # we have to clean the whole Bundle.
              Bundler.load.clean(true)
              Bundler.reset!
              # Finally, we install the new runtime and require it to load the CI's dependencies
              # as they were before the build.
              Bundler::Plugin.gemfile_install(Bundler.default_gemfile)
              definition = Bundler.definition
              definition.validate_runtime!
              Bundler::Installer.install(Bundler.root, definition, { dry_run: true })
              Bundler.require
            end
          end
        end

        current_build.status = :success
        current_build.description = "All green"
        logger.info("fastlane run complete")

        artifacts_paths = gather_build_artifact_paths(loggers: [verbose_log, info_log])
      rescue StandardError => ex
        logger.debug("Setting build status to failure due to exception")
        current_build.status = :ci_problem
        current_build.description = "fastlane.ci encountered an error, check fastlane.ci logs for more information"

        logger.error(ex)
        logger.error(ex.backtrace)

        # Catching the exception with this rescue block is really important,
        # as we also need to notify the listeners about it
        # see https://github.com/fastlane/ci/issues/583 for more details
        # notify all interested parties here
        # TODO: the line below could be improved
        #   right now we're just setting everything to `crash`
        #   to indicate this is causes a build failure
        new_line_block.call(convert_raw_row_to_object({
          type: "crash",
          message: ex.to_s,
          time: Time.now
        }))
        ci_output.output_listeners.each do |listener|
          listener.error(ex.to_s)
        end

        artifacts_paths = gather_build_artifact_paths(loggers: [verbose_log, info_log])
      ensure
        # TODO: what happens if `rescue` causes an exception
        completion_block.call(artifacts_paths)
      end
    end

    def convert_raw_row_to_object(raw_row)
      # Additionally to transfering the original metadata of this message
      # that look like this:
      #
      #   {:type=>:success, :message=>"Everything worked", :time=>...}
      #
      # we append the HTML code that should be used in the `html` key
      # the result looks like this
      #
      #   {
      #     "type": "success",
      #     "message": "Driving the lane 'ios beta'",
      #     "html": "<p class=\"success\">Driving the lane 'ios beta'</p>",
      #     "time" => ...
      #   }
      #
      # Also we use our custom BuildRunnerOutputRow class to represent the current row
      current_row = FastlaneCI::BuildRunnerOutputRow.new(
        type: raw_row[:type],
        message: raw_row[:message],
        time: raw_row[:time]
      )
      return current_row
    end

    # Responsible for setting up Xcode build environment
    def setup_tooling_environment?
      xcode_version_file_path = File.join(repo.local_folder, ".xcode-version")
      unless File.exist?(xcode_version_file_path)
        logger.debug("No `.xcode-version` file found for repo '#{project.project_name}', " \
                     "not managing Xcode for this one...")
        return true # we're ok with this, all good to run the build
      end

      xcode_version_to_use = File.read(xcode_version_file_path).strip
      begin
        parsed_xcode_version = Gem::Version.new(xcode_version_to_use)
      rescue ArgumentError => ex
        logger.error("Invalid version specification in `.xcode-version` file, make sure it's valid: #{ex}")
        return true # we're ok with this, let's keep the system default Xcode
      end

      # valid Xcode version specification
      # let's see if the version exists
      matching_xcode_instance = Services.xcode_manager_service.installed_xcode_versions.find do |xcode|
        xcode.bundle_version == parsed_xcode_version
      end

      if matching_xcode_instance
        new_row(
          BuildRunnerOutputRow.new(
            type: "important",
            message: "Xcode #{parsed_xcode_version} is defined and installed, switching to using it",
            time: Time.now
          )
        )
        @xcode_path_to_use = matching_xcode_instance.path
        return true
      else
        # This version isn't installed yet, let's see if it's available to install
        if Services.xcode_manager_service.installer.exist?(parsed_xcode_version)
          # Let the git remote know we're installing Xcode, as it will significantly delay this build
          current_build.status = :installing_xcode
          save_build_status! # tell the git remote

          new_row(
            BuildRunnerOutputRow.new(
              type: "important",
              message: "Installing Xcode version #{parsed_xcode_version}... this might take a while",
              time: Time.now
            )
          )

          Services.xcode_manager_service.install_xcode!(
            version: parsed_xcode_version,
            success_block: proc do |version|
              # we don't have to set any Xcode path here
              # as basically we're putting the build back into the queue again
              # which will then detect the newly installed Xcode version
              # and switch the path automatically #magic
              puts "Success: #{version}"
              # Put the build back into the queue
              Services.build_runner_service.add_build_runner(build_runner: self)
            end,
            error_block: proc do |version, exception|
              puts "Error: #{version} - #{exception}"
              # TODO: raise an exception here and make the build fail
              # It might not be enough to just raise it here
              # we have to test it
              raise "Error installing Xcode"
            end
          )

          return false
        else
          # TODO: make sure this marks the build as failed
          raise "#{parsed_xcode_version} is not available to be installed for build #{current_build}"
        end
      end
    end

    protected

    def gather_build_artifact_paths(loggers:)
      artifact_paths = []
      loggers.each do |current_logger|
        next unless File.exist?(current_logger.file_path)
        artifact_paths << {
          type: File.basename(current_logger.file_path),
          path: File.expand_path(current_logger.file_path)
        }
      end
      constants_with_path =
        Fastlane::Actions::SharedValues.constants
                                       .select { |value| value.to_s.include?("PATH") } # Far from ideal
                                       .select do |value|
                                         !Fastlane::Actions.lane_context[value].nil? &&
                                           !Fastlane::Actions.lane_context[value].empty?
                                       end
                                       .map do |value|
                                         { type: value.to_s, path: Fastlane::Actions.lane_context[value] }
                                       end
      return artifact_paths.concat(constants_with_path)
    end
  end
end
