require_relative "github_provider"
module FastlaneCI
  # User model that will end up in the session as session[:user]
  class User
    attr_accessor :email
    attr_accessor :password_hash

    attr_accessor :providers # Array of {GitHubProvider, BitBucketProvider, etc...}

    def initialize(email: nil, password_hash: nil, providers: nil)
      @email = email
      @password_hash = password_hash
      @providers = providers
    end

    # return the provider specified
    def provider(type: PROVIDER_TYPES[:github])
      return self.providers.select { |provider| provider.type == type }.first
    end
  end
end
