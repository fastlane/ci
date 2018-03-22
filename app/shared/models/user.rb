require "securerandom"
require_relative "provider_credential"
require_relative "github_provider_credential"

module FastlaneCI
  # User model that will end up in the session as session[:user]
  class User
    attr_accessor :id
    attr_accessor :email
    attr_accessor :password_hash

    attr_accessor :provider_credentials # Array of {GitHubProviderCredential, BitBucketProvider, etc...}

    def initialize(id: nil, email: nil, password_hash: nil, provider_credentials: [])
      @id = id || SecureRandom.uuid
      @email = email
      @password_hash = password_hash
      @provider_credentials = provider_credentials
    end

    # return the provider_credential specified, right now it assumes type is unique
    def provider_credential(type: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])
      return self.provider_credentials.select { |provider_credential| provider_credential.type == type }.first
    end
  end
end
