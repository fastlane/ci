require "securerandom"

module FastlaneCI
  # `AppleID` model representing a single Apple ID login
  # This class is similar to `EnvironmentVariable`
  class AppleID
    attr_accessor :user

    # currently we don't support 2 step verification for Apple IDs yet
    # tracked via https://github.com/fastlane/ci/issues/639

    # The prefix is used for the iTunesTransporter password, it's an application
    # specific password. This is not implemented in fastlane.ci yet, but will be soon
    # https://github.com/fastlane/ci/issues/1082
    attr_accessor :prefix

    def initialize(user: nil, password: nil, prefix: nil)
      @user = user
      self.password = password # we use `self` to trigger encrypting the password
      @prefix = prefix
    end

    def password=(new_password)
      @password = new_password

      if new_password.to_s.length > 0
        # We set the @ variable here for the `JSONConvertible` to pick it up
        @encrypted_password = encrypted_password
      end
    end

    # We also have to provide this as a custom reader and potentially re-encrypt
    # the password. This is needed as `JSONConvertible` accesses @ variables directly.
    # Also `JSONConvertible` loads the existing `environment_variables.json` and sets the
    # values directly to the @ variables without using the setter
    def encrypted_password
      Base64.encode64(StringEncrypter.encode(@password))
    end

    # Similar to the comment of the `encrypted_password` method, we have to decrypt the password
    # on the fly, as the `JSONConvertible` accesses @ variables directly instead of
    # using the setter
    def password
      if @encrypted_password.to_s.length > 0 && @password.to_s.length == 0
        @password = StringEncrypter.decode(Base64.decode64(@encrypted_password))
      end
      return @password
    end
  end
end
