require_relative "./fastlane_build_runner_helpers/fastlane_ci_output"
require_relative "./fastlane_build_runner_helpers/fastlane_log"
require_relative "./fastlane_build_runner_helpers/fastlane_output_to_html"
require_relative "./build_runner"
require_relative "../../shared/fastfile_finder"

require "tmpdir"

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
      @encountered_failure_output = false # Did we encounter a row that signaled failure?
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

        completion_block.call([])
        return
      end

      fast_file = Fastlane::FastFile.new(fast_file_path)
      FastlaneCore::Globals.verbose = true

      begin
        # TODO: I think we need to clear out the singleton values, such as lane context, and all that jazz
        # Execute the Fastfile here
        # rubocop:disable Metrics/LineLength
        logger.info("starting fastlane run lane: #{lane} platform: #{platform}, params: #{parameters} from #{fast_file_path}")
        # rubocop:enable Metrics/LineLength

        # Attach a listener to the output to see if we have a failure. If so, this build failed
        add_listener(proc do |row|
          @encountered_failure_output = true if row.did_fail_build?
        end)

        build_output = ["#{fast_file_path}, #{lane} platform: #{platform}, params: #{parameters} from output"]
        # Attach a listener so we can collect the build output and display it all at once
        add_listener(proc do |row|
          build_output << "#{row.time}: #{row.message}"
        end)

        # TODO: the fast_file.runner should probably handle this
        logger.debug("Switching to #{repo.local_folder} to run `fastlane`")
        # Change over to the repo
        Dir.chdir(repo.local_folder)

        # Make sure to load all the dependencies of the Gemfile
        # TODO: support projects that don't have a Gemfile defined
        Bundler.with_clean_env do
          # Run fastlane now
          fast_file.runner.execute(lane, platform, parameters)
        end

        if @encountered_failure_output
          current_build.status = :failure
        else
          current_build.status = :success
        end

        logger.info("fastlane run complete")
        logger.debug(build_output.join("\n").to_s)

        artifacts_paths = gather_build_artifact_paths(loggers: [verbose_log, info_log])
      rescue StandardError => ex
        logger.debug("Setting build status to failure due to exception")
        current_build.status = :ci_problem
        current_build.description = "fastlane.ci encountered an error, check fastlane.ci logs for more information"

        logger.error(ex)
        logger.error(ex.backtrace)

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
          type: "log",
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
