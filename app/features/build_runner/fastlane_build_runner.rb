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

    # Set additional values specific to the fastlane build runner
    def setup(parameters: nil)
      # TODO: We have to update `Project` to properly let the user define platform and lane
      #   Currently we just split the string
      #   See https://github.com/fastlane/ci/issues/236
      lane_pieces = project.lane.split(" ")

      # Setting the variables directly (only having `attr_reader`) as they're immutable
      # Once you define a FastlaneBuildRunner, you shouldn't be able to modify them
      @platform = lane_pieces.count > 1 ? lane_pieces.first : nil
      @lane = lane_pieces.last
      @parameters = parameters
    end

    # completion_block is called with an array of artifacts
    def run(new_line_block:, completion_block:)
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

        # We call the safe (because is synchronized) Bundler's `chdir` and
        # install all the dependencies, if any.
        Bundler::SharedHelpers.chdir(repo.local_folder) do
          ENV["FASTLANE_SKIP_DOCS"] = true.to_s

          gemfile_found = Dir[File.join(Dir.pwd, "**", "Gemfile")].any?
          if gemfile_found
            begin
              # Reset the bundler scope to the Project's Gemfile.
              gemfile_dir = Dir[File.join(Dir.pwd, "**", "Gemfile")].first
              Bundler::SharedHelpers.set_env("BUNDLE_GEMFILE", gemfile_dir)

              old_root = Bundler.method(:root)
              # rubocop:disable Lint/NestedMethodDefinition
              def Bundler.root
                Bundler::SharedHelpers.pwd.expand_path
              end
              # rubocop:enable Lint/NestedMethodDefinition

              Bundler::Plugin.gemfile_install(gemfile_dir) if Bundler.feature_flag.plugins?
              builder = Bundler::Dsl.new
              builder.eval_gemfile(gemfile_dir)

              definition = builder.to_definition(nil, true)
              def definition.lock(*); end
              definition.validate_runtime!

              installer = Bundler::Installer.new(Bundler.root, definition)

              missing_specs = proc do
                definition.missing_specs?
              end

              options = {}
              options[:no_install] = false
              options[:force] = true

              Bundler.load.specs.each do |spec|
                next if spec.name == "bundler" # Source::Rubygems doesn't install bundler
                next if !@gems.empty? && !@gems.include?(spec.name)
        
                gem_name = "#{spec.name} (#{spec.version}#{spec.git_version})"
                gem_name += " (#{spec.platform})" if !spec.platform.nil? && spec.platform != Gem::Platform::RUBY
        
                case source = spec.source
                when Source::Rubygems
                  cached_gem = spec.cache_file
                  unless File.exist?(cached_gem)
                    Bundler.ui.error("Failed to pristine #{gem_name}. Cached gem #{cached_gem} does not exist.")
                    next
                  end
        
                  FileUtils.rm_rf spec.full_gem_path
                when Source::Git
                  source.remote!
                  if extension_cache_path = source.extension_cache_path(spec)
                    FileUtils.rm_rf extension_cache_path
                  end
                  FileUtils.rm_rf spec.extension_dir
                  FileUtils.rm_rf spec.full_gem_path
                else
                  Bundler.ui.warn("Cannot pristine #{gem_name}. Gem is sourced from local path.")
                  next
                end
        
                Bundler::GemInstaller.new(spec, installer, false, 0, true).install_from_spec
              end

              require "pry"
              binding.pry

              # rubocop:disable Metrics/LineLength
              logger.info("Bundle complete! #{definition.dependencies.count} Gemfile dependencies, installed #{definition.specs.count} gems.")
              # rubocop:enable Metrics/LineLength
              runtime = Bundler::Runtime.new(nil, definition)
              Bundler::SharedHelpers.set_bundle_environment
              runtime.setup.require
              not_installed = definition.missing_specs
              if not_installed.any?
                logger.error("The following gems are missing")
                not_installed.each { |s| logger.error(" * #{s.name} (#{s.version})") }
              end
            rescue Bundler::GemfileNotFound => ex
              logger.info(ex)
            rescue Gem::LoadError => ex
              logger.error(ex)
            rescue StandardError => ex
              logger.error(ex)
              logger.error(ex.backtrace)
            ensure
              bundler_module = class << Bundler; self; end
              bundler_module.send(:define_method, :root, old_root) if old_root
            end
          end

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
      current_row.html = FastlaneOutputToHtml.convert_row(current_row)
      return current_row
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
