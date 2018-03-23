require "base64"

require_relative "provider_credential"
require_relative "../string_encrypter"

module FastlaneCI
  # GitHub ProviderCredential class
  class GitHubProviderCredential < ProviderCredential
    # @return [String]
    attr_accessor :encrypted_api_token

    # @return [String]
    attr_accessor :email

    # @return [PROVIDER_CREDENTIAL_TYPES]
    attr_accessor :type

    # @return [String]
    attr_accessor :provider_name

    # @return [String]
    attr_accessor :full_name

    # @return [String]
    attr_accessor :remote_host

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
        self.encrypted_api_token = nil
      else
        new_encrypted_api_token = StringEncrypter.encode(value)
        self.encrypted_api_token = Base64.encode64(new_encrypted_api_token)
      end
    end

    def api_token
      return nil if self.encrypted_api_token.nil?
      return StringEncrypter.decode(Base64.decode64(self.encrypted_api_token))
    end
  end
end
