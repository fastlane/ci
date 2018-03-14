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

    def initialize(type: nil, message: nil, time: nil, html: nil)
      self.type = type
      self.message = message
      self.time = time
      self.html = html
    end
  end
end
