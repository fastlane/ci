module FastlaneCI
  # Represents a single "Row" when streaming the build output (might be coming from fastlane)
  # meaning it's a single message that we want to show to the user
  # and store as a build artifact as part of the build log
  class BuildRunnerOutputRow
    BUILD_FAIL_TYPES = [:user_error, :build_error, :crash, :error, :shell_error, :build_failure, :test_failure, :abort].to_set

    # The type of message (e.g. `:message`, `:error`, `:important`)
    attr_accessor :type

    # The raw message to show
    attr_accessor :message

    # Timestamp (Time)
    attr_accessor :time

    # The plan is to remove this, as we want to render it on the front-end
    # Tracked as GitHub issue https://github.com/fastlane/ci/issues/213
    attr_accessor :html

    def initialize(type:, message:, time:)
      self.type = type
      self.message = message
      self.time = time
    end

    # Did this particular message fail the build? (e.g. `user_error` or `build_error`)
    def did_fail_build?
      # The first time this method is called, we check if this row failed the build
      if self._did_fail_build.nil?
        self._did_fail_build = BUILD_FAIL_TYPES.include?(self.type)
      end
      return self._did_fail_build
    end

    def to_json
      return {
        type: self.type,
        message: self.message,
        time: self.time,
        html: self.html
      }.to_json
    end
  end
end
