module FastlaneCI
  # Represents a single "Row" when streaming the build output (might be coming from fastlane)
  # meaning it's a single message that we want to show to the user
  # and store as a build artifact as part of the build log
  class BuildRunnerOutputRow
    BUILD_FAIL_TYPES = [
      :user_error,
      :build_error,
      :crash,
      :shell_error,
      :build_failure,
      :test_failure,
      :abort
    ].to_set

    # The type of message (e.g. `:message`, `:error`, `:important`)
    attr_reader :type

    # The raw message to show
    attr_reader :message

    # The plan is to remove this, as we want to render it on the front-end
    # Tracked as GitHub issue https://github.com/fastlane/ci/issues/213
    attr_accessor :html

    # Timestamp (Time)
    attr_reader :time

    def initialize(type:, message:, time:)
      @type = type
      @message = message
      @time = time

      @html = FastlaneOutputToHtml.convert_row(self)
    end

    # Is this the last row? We guarantee that we send this out to listeners
    # as it allows the observer to properly clean things up
    def last_message?
      return type == :last_message
    end

    def to_json
      return {
        type: type,
        message: message,
        time: time,
        html: html
      }.to_json
    end
  end
end
