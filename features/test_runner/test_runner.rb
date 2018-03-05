module FastlaneCI
  # Abstract class that represents a test runner, used
  # to run tests for a given commit sha
  class TestRunner
    # @return [Array[String]] of references for the different artifacts created by the runner.
    def run(*args)
      not_implemented(__method__)
    end
  end
end

require_relative "./fastlane_test_runner"
