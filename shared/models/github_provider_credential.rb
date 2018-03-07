require "base64"

require_relative "provider_credential"
require_relative "../string_encrypter"

module FastlaneCI
  # GitHub ProviderCredential class
  class GitHubProviderCredential < ProviderCredential
    attr_accessor :encrypted_api_token

    def initialize(id: nil, email: nil, full_name: nil, api_token: nil)
      self.id = id || SecureRandom.uuid
      self.email = email
      self.full_name = full_name
      self.api_token = api_token
      self.provider_name = "GitHub"
      self.type = PROVIDER_CREDENTIAL_TYPES[:github]
      self.remote_host = "github.com"
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

    def email
      return @email
    end

    def type
      return @type
    end

    def provider_name
      return @provider_name
    end

    def full_name
      return @full_name
    end

    def remote_host
      return @remote_host
    end

    # TODO, this shouldn't be necesary, but we don't recurse properly in JSONConvertible
    def dictionary_value
      return { "email" => @email, "encrypted_api_token" => @encrypted_api_token }
    end
  end
end
