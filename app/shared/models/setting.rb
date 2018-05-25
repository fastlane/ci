module FastlaneCI
  # Setting model representing a single entry of a fastlane.ci system setting
  class Setting
    attr_accessor :key
    attr_accessor :value
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
  end
end

# TODO:
# 1) What if the user defines a Setting whose key we don't support
# 2) I need pre-load the available_settings and then fill in *just the values* from the `settings.json`
