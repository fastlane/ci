module FastlaneCI
  # Represents a single "Row" when streaming the build output (might be coming from fastlane)
  # meaning it's a single message that we want to show to the user
  # and store as a build artifact as part of the build log
  class BuildRunnerOutputRow
    # The type of message (e.g. `:message`, `:error`, `:important`)
    attr_accessor :type

    # The raw message to show
    attr_accessor :message

    # Timestamp (Time)
    attr_accessor :time

    # The plan is to remove this, as we want to render it on the front-end
    attr_accessor :html

    def initialize(type: nil, message: nil, time: nil)
      self.type = type
      self.message = message
      self.time = time
    end

    # Did this particular message fail the build? (e.g. `user_error` or `build_error`)
    def did_fail_build?
      return true if [:user_error, :build_error, :crash, :shell_error, :build_failure, :test_failure, :abort].include?(self.type)
      return false
    end

    def to_json
      return {
        type: self.type,
        message: self.message,
        time: self.time,
        html: self.html
      }
    end
  end
end
