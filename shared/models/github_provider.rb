require "base64"

require_relative "provider_credential"
require_relative "../string_encrypter"

module FastlaneCI
  # GitHub ProviderCredential class
  class GitHubProvider < ProviderCredential
    attr_accessor :email # email used on github
    attr_accessor :encrypted_api_token

    def initialize(email: nil, api_token: nil)
      self.email = email
      self.api_token = api_token
      self.provider_name = "GitHub"
      self.type = PROVIDER_TYPES[:github]
    end

    def api_token=(value)
      if value.nil?
        @encrypted_api_token = nil
      else
        new_encrypted_api_token = StringEncrypter.encode(value)
        @encrypted_api_token = Base64.encode64(new_encrypted_api_token)
      end
    end

    def api_token
      return nil if @encrypted_api_token.nil?
      return StringEncrypter.decode(Base64.decode64(@encrypted_api_token))
    end

    def type
      return @type
    end

    def provider_name
      return @provider_name
    end

    # TODO, this shouldn't be necesary, but we don't recurse properly in JSONConvertible
    def dictionary_value
      return { "email" => @email, "encrypted_api_token" => @encrypted_api_token }
    end
  end
end
