require "securerandom"
require_relative "provider_credential"
require_relative "github_provider"

module FastlaneCI
  # User model that will end up in the session as session[:user]
  class User
    attr_accessor :id
    attr_accessor :email
    attr_accessor :password_hash

    attr_accessor :providers # Array of {GitHubProvider, BitBucketProvider, etc...}

    def initialize(id: nil, email: nil, password_hash: nil, providers: nil)
      @id = id || SecureRandom.uuid
      @email = email
      @password_hash = password_hash
      @providers = providers
    end

    # return the provider specified, right now it assumes type is unique
    def provider(type: FastlaneCI::ProviderCredential::PROVIDER_TYPES[:github])
      return self.providers.select { |provider| provider.type == type }.first
    end
  end
end
