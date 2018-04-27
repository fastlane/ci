require "securerandom"

module FastlaneCI
  # EnvironmentVariable model representing a single entry of an env variable
  class EnvironmentVariable
    attr_accessor :key

    def initialize(key: nil, value: nil)
      @key = key
      self.value = value # we use `self` to trigger encrypting the value
    end

    def value=(new_value)
      @value = new_value

      if new_value.to_s.length > 0
        # We set the @ variable here for the `JSONConvertible` to pick it up
        @encrypted_value = encrypted_value
      end
    end

    # We also have to provide this as a custom reader and potentially re-encrypt
    # the value. This is needed as `JSONConvertible` accesses @ variables directly.
    # Also `JSONConvertible` loads the existing `environment_variables.json` and sets the
    # values directly to the @ variables without using the setter
    def encrypted_value
      Base64.encode64(StringEncrypter.encode(@value))
    end

    # Similar to the comment of the `encrypted_value` method, we have to decrypt the value
    # on the fly, as the `JSONConvertible` accesses @ variables directly instead of
    # using the setter
    def value
      if @encrypted_value.to_s.length > 0 && @value.to_s.length == 0
        @value = StringEncrypter.decode(Base64.decode64(@encrypted_value))
      end
      return @value
    end
  end
end
