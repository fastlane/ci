require "base64"

require_relative "provider_credential"
require_relative "../string_encrypter"

module FastlaneCI
  # GitHub ProviderCredential class
  class GitHubProviderCredential < ProviderCredential
    # @return [String]
    attr_reader :id

    # @return [String]
    attr_reader :email

    # @return [PROVIDER_CREDENTIAL_TYPES]
    attr_reader :type

    # @return [String]
    attr_reader :provider_name

    # e.g. "Initial Onboarding User credentials"
    # @return [String]
    attr_reader :full_name

    # @return [String]
    attr_reader :remote_host

    attr_accessor :encrypted_api_token

    def initialize(id: nil, email: nil, full_name: nil, api_token: nil)
      @id = id || SecureRandom.uuid
      @email = email
      @full_name = full_name
      @provider_name = "GitHub"
      @type = PROVIDER_CREDENTIAL_TYPES[:github]
      @remote_host = "github.com"
      @encrypted_api_token = encrypt_api_token(api_token)
    end

    def encrypt_api_token(token)
      if token.nil?
        return nil
      else
        new_encrypted_api_token = StringEncrypter.encode(token)
        return Base64.encode64(new_encrypted_api_token)
      end
    end

    def api_token=(value)
      @encrypted_api_token = encrypt_api_token(value)
    end

    def api_token
      return nil if @encrypted_api_token.nil?
      return StringEncrypter.decode(Base64.decode64(@encrypted_api_token))
    end
  end
end
