module FastlaneCI
  # Encapsulates the possibility of a return value
  # Always check `success?` before pulling the `value`
  # If not `success?` then the `value` is only there for context on why the result wasn't a success
  # Do not use the `value` as a result if `success?` is false.
  class Result
    attr_accessor :value
    def success?
      return @success
    end

    def initialize(success:, value:)
      @success = success
      @value = value
    end
  end
end
