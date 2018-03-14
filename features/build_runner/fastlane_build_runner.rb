require_relative "./fastlane_build_runner_helpers/fastlane_ci_output"
require_relative "./fastlane_build_runner_helpers/fastlane_log"
require_relative "./fastlane_build_runner_helpers/fastlane_output_to_html"
require_relative "./build_runner"

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
      lane_pieces = self.project.lane.split(" ")

      # Setting the variables directly (only having `attr_reader`) as they're immutable
      # Once you define a FastlaneBuildRunner, you shouldn't be able to modify them
      @platform = lane_pieces.count > 1 ? lane_pieces.first : nil
      @lane = lane_pieces.last
      @parameters = parameters
    end

    def run
      raise "No block provided for `run` method" unless block_given?
      require "fastlane"

      ci_output = FastlaneCI::FastlaneCIOutput.new(
        each_line_block: proc do |row|
          # Additionally to transfering the original metadata of this message
          # that look like this:
          #
          #   {:type=>:success, :message=>"Everything worked", :time=>...}
          #
          # we append the HTML code that should be used in the `html` key
          # the result looks like this
          #
          #   {"type":"success","message":"Driving the lane 'ios beta'","html":"<p class=\"success\">Driving the lane 'ios beta'</p>","time"=>...}
          #
          row[:html] = FastlaneOutputToHtml.convert_row(row)
          yield(row)
        end
      )

      verbose_log = FastlaneCI::FastlaneLog.new(file_path: "fastlane.verbose.log", severity: Logger::DEBUG)
      info_log = FastlaneCI::FastlaneLog.new(file_path: "fastlane.log")

      ci_output.add_output_listener!(verbose_log)
      ci_output.add_output_listener!(info_log)

      FastlaneCore::UI.ui_object = ci_output

      # this only takes a few ms the first time being called
      Fastlane.load_actions

      fast_file_path = self.project.local_fastfile_path
      fast_file = Fastlane::FastFile.new(fast_file_path)
      FastlaneCore::Globals.verbose = true

      begin
        # TODO: I think we need to clear out the singleton values, such as lane context, and all that jazz
        # Execute the Fastfile here
        logger.info("starting fastlane run lane: #{self.lane} platform: #{self.platform}, params: #{self.parameters} from #{fast_file_path}")

        build_success = true
        # Attach a listener to the output to see if we have a failure. If so, this build failed
        self.add_listener(proc do |row|
          build_success = false if row[:type] == :error
        end)

        build_output = ["#{fast_file_path}, #{self.lane} platform: #{self.platform}, params: #{self.parameters} from output"]
        # Attach a listener so we can collect the build output and display it all at once
        self.add_listener(proc do |row|
          build_output << "#{row[:time]}: #{row[:message]}"
        end)

        fast_file.runner.execute(self.lane, self.platform, self.parameters)

        if build_success
          self.current_build.status = :success
        else
          self.current_build.status = :failure
        end

        logger.info("fastlane run complete")
        logger.debug(build_output.join("\n").to_s)

        return [] # TODO: return artifacts here
      rescue StandardError => ex
        # TODO: Exception handling here
        logger.error(ex)
        logger.error(ex.backtrace)
        return [] # TODO: return artifacts here (if any)
        # ensure
        # Either the build was successfull or not, we have to ensure the artifacts for the execution.
        # artifact_paths = []
        # artifact_paths << { type: "log", path: "fastlane.log" }
        # constants_with_path = Fastlane::Actions::SharedValues.constants
        #                                                      .select { |value| value.to_s.include?("PATH") } # Far from ideal, but meanwhile...
        #                                                      .select { |value| !Fastlane::Actions.lane_context[value].nil? && !Fastlane::Actions.lane_context[value].empty? }
        #                                                      .map { |value| { type: value.to_s, path: Fastlane::Actions.lane_context[value] } }
        # artifact_paths.concat(constants_with_path)
      end
    end
  end
end
