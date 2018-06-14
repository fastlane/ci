module FastlaneCI
  # Base class for all build runner change listeners
  class BuildRunnerChangeListener
    # If the listener is no longer listening, return true.
    # Once this returns `true` the build runner will never attempt to use it again.
    # That means that the first time an instance returns `true`, it will never be used again unless
    # explicitly re-added as a listener to the BuildRunner (not recommended)
    def done_listening?
      not_implemented(__method__)
    end

    def row_received(row)
      not_implemented(__method__)
    end
  end
end
