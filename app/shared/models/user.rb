require "securerandom"
require_relative "provider_credential"
require_relative "github_provider_credential"

module FastlaneCI
  # User model that will end up in the session as session[:user]
  class User
    # @return [String] The UUID of the user
    attr_accessor :id

    # @return [String] The email associated with the User's account
    attr_accessor :email

    # @return [String] A password hash encrypted with the `FASTLANE_CI_ENCRYPTION_KEY`
    attr_accessor :password_hash

    # @return [Array[ProviderCredential]] {GitHubProviderCredential, BitBucketProvider, etc...}
    attr_accessor :provider_credentials

    # Creates a `User` model associated with a fastlane.ci account.
    #
    # NOTE: The `id` parameter can be `nil`, because you may want to create a
    # `User` model from an existing record in the `JSONUserDataSource` which has
    # an existing `id`.
    #
    # An example of this is when you wish to update an existing user. The
    # `update_user!` method in the `UserDataSource` takes in a `User` as a
    # required parameter, and looks up said user by its `id` in the `find_user`
    # method.
    #
    # @param [String] id: an optional UUID parameter. If the parameter is `nil`
    #   will create a new UUID for the user
    # @param [String] email: a required parameter denoting the user's email
    # @param [String] password_hash: a required parameter denoting the user's
    #   password, encrypted with the `FASTLANE_CI_ENCRYPTION_KEY`
    # @param [Array[ProviderCredential]] provider_credentials: an optional
    #   parameter denoting provider credentials for code hosting services
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
  end
end
