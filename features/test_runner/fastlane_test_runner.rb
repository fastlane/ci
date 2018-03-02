require_relative "./fastlane_test_runner_helpers/fastlane_ci_output"
require_relative "./fastlane_test_runner_helpers/fastlane_output_to_html"

module FastlaneCI
  # Represents the test runner responsible for loading and running
  # fastlane Fastfile configurations
  class FastlaneTestRunner < TestRunner
    # Parameters for running fastlane
    attr_reader :platform
    attr_reader :lane
    attr_reader :parameters

    def initialize(platform: nil, lane: nil, parameters: nil)
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
          # {:type=>:success, :message=>"Everything worked"}
          # 
          # we append the HTML code that should be used in the `html` key
          # the result looks like this
          #
          # {"type":"success","message":"Driving the lane 'ios beta' 🚀","html":"<p class=\"success\">Driving the lane 'ios beta' 🚀</p>"}
          #
          row[:html] = FastlaneOutputToHtml.convert_row(row)

          yield(row)
        end
      )
      FastlaneCore::UI.ui_object = ci_output

      # this only takes a few ms the first time being called
      Fastlane.load_actions

      # Load and parse the Fastfile
      fast_file = Fastlane::FastFile.new(FastlaneCore::FastlaneFolder.fastfile_path)

      begin
        # Execute the Fastfile here
        fast_file.runner.execute(self.lane, self.platform, self.parameters)
        puts("Big success")
        # TODO: success handling here
        # this all will be implemented using a separate PR
        # once we have the web socket streaming implemented
      rescue StandardError => ex
        # TODO: Exception handling here
        require "pry"; binding.pry
        puts(ex)
      end
    end
  end
end
