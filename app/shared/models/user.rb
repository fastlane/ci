require "securerandom"
require_relative "provider_credential"
require_relative "github_provider_credential"
require_relative "../json_convertible"

module FastlaneCI
  # User model that will end up in the session as session[:user]
  class User
    include FastlaneCI::JSONConvertible

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
      return provider_credentials.detect { |provider_credential| provider_credential.type == type }
    end

    def self.attribute_to_type_map
      return { :@provider_credentials => GitHubProviderCredential }
    end

    def self.map_enumerable_type(enumerable_property_name: nil, current_json_object: nil)
      if enumerable_property_name == :@provider_credentials
        type = current_json_object["type"]
        # currently only supports 1 type, but we could automate this part too
        provider_credential = nil
        if type == FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
          provider_credential = GitHubProviderCredential.from_json!(current_json_object)
        end
        provider_credential
      end
    end
  end
end
