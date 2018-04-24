require "securerandom"

module FastlaneCI
  # EnvironmentVariable model representing a single entry of an env variable
  class EnvironmentVariable
    attr_accessor :key
    attr_accessor :value

    def initialize(key: nil, value: nil)
      @key = key
      @value = value
    end
  end
end
