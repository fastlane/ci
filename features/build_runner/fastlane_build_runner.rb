require_relative "./fastlane_build_runner_helpers/fastlane_ci_output"
require_relative "./fastlane_build_runner_helpers/fastlane_output_to_html"
require_relative "./build_runner"

module FastlaneCI
  # Represents the build runner responsible for loading and running
  # fastlane Fastfile configurations
  # TODO: run method *should* return an array of artifacts
  class FastlaneBuildRunner < BuildRunner
    include FastlaneCI::Logging

    # Parameters for running fastlane
    attr_reader :platform
    attr_reader :lane
    attr_reader :parameters

    def setup(platform: nil, lane: nil, parameters: nil)
      @platform = platform
      @lane = lane
      @parameters = parameters
    end

    def run
      raise "No block provided for `run` method" unless block_given?
      require "fastlane"

      ci_output = FastlaneCI::FastlaneCIOutput.new(
        file_path: "fastlane.log",
        each_line_block: proc do |row|
          # Additionally to transfering the original metadata of this message
          # that look like this:
          #
          #   {:type=>:success, :message=>"Everything worked"}
          #
          # we append the HTML code that should be used in the `html` key
          # the result looks like this
          #
          #   {"type":"success","message":"Driving the lane 'ios beta'","html":"<p class=\"success\">Driving the lane 'ios beta'</p>"}
          #
          row[:html] = FastlaneOutputToHtml.convert_row(row)
          yield(row)
        end
      )
      FastlaneCore::UI.ui_object = ci_output

      # this only takes a few ms the first time being called
      Fastlane.load_actions

      # Load and parse the Fastfile
      # TODO: This won't work for now, as it is evaluating to the local CI fastlane.
      fast_file = Fastlane::FastFile.new(FastlaneCore::FastlaneFolder.fastfile_path)

      begin
        # Execute the Fastfile here
        puts("starting fastlane run")
        fast_file.runner.execute(self.lane, self.platform, self.parameters)
        puts("fastlane run complete")
        # TODO: success handling here
        # this all will be implemented using a separate PR
        # once we have the web socket streaming implemented
      rescue StandardError => ex
        # TODO: Exception handling here
        puts(ex)
        puts(ex.backtrace)
      ensure
        # Either the build was successfull or not, we have to ensure the artifacts for the execution.
        artifact_paths = []
        artifact_paths << { type: "log", path: "fastlane.log" }
        constants_with_path = Fastlane::Actions::SharedValues.constants
                                                             .select { |value| value.to_s.include?("PATH") } # Far from ideal, but meanwhile...
                                                             .select { |value| !Fastlane::Actions.lane_context[value].nil? && !Fastlane::Actions.lane_context[value].empty? }
                                                             .map { |value| { type: value.to_s, path: Fastlane::Actions.lane_context[value] } }
        return artifact_paths.concat(constants_with_path)
      end
    end
  end
end
