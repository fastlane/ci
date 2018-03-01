require_relative "./fastlane_test_runner_helpers/fastlane_ci_output"

module FastlaneCI
  # Represents the test runner responsible for loading and running
  # fastlane Fastfile configurations
  class FastlaneTestRunner < TestRunner
    def run(platform: nil, lane: nil, parameters: nil)
      require "fastlane"

      ci_output = FastlaneCI::FastlaneCIOutput.new(
        file_path: "fastlane.log",
        block: proc do |row|
          puts "Current output from fastlane: #{row}"

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
        fast_file.runner.execute(lane, platform, parameters)
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
