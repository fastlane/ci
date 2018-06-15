module FastlaneCI
  # Setting model representing a single entry of a fastlane.ci system setting
  class Setting
    attr_accessor :key
    attr_reader :value
    attr_accessor :verify_block
    attr_accessor :default_value
    attr_accessor :description

    def initialize(key: nil, description: nil, value: nil, default_value: nil, verify_block: nil)
      @key = key
      @default_value = default_value
      @verify_block = verify_block
      @description = description

      self.value = value # to call the `verify_block` (if provided)
    end

    def value=(value)
      if value.to_s.length > 0
        verify_block.call(value) if verify_block
      end

      @value = value
    end

    def reset!
      self.value = nil # nil won't trigger the `verify_block` anyway
    end
  end
end
