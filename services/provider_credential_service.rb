require_relative "./services"
require_relative "../shared/logging_module"

module FastlaneCI
  # Provides access to provider credential related methods
  class ProviderCredentialService
    include FastlaneCI::Logging

    # Creates a new provider credential, and adds it to the User's provider
    # credentials array
    def create_provider_credential!(
      user_id: nil, id: nil, email: nil, api_token: nil, provider_name: nil,
      full_name: nil
    )
      provider_credential = GitHubProviderCredential.new(
        id: id, email: email, api_token: api_token, provider_name: provider_name,
        full_name: full_name
      )
      user = Services.user_service.find_user(id: user_id)

      new_user = User.new(
        id: user.id,
        email: user.id,
        password: user.password_hash,
        provider_credentials: user.provider_credentials.push(provider_credential)
      )
      Services.user_service.update_user!(new_user)
    end

    def update_provider_credential!(
      user_id: nil, id: nil, email: nil, api_token: nil, provider_name: nil,
      full_name: nil
    )
      provider_credential = GitHubProviderCredential.new(
        email: email, api_token: api_token, provider_name: provider_name,
        full_name: full_name
      )
      user = Services.user_service.find_user(id: user_id)

      new_user = User.new(
        id: user.id,
        email: user.id,
        password: user.password_hash,
        provider_credentials: user.provider_credentials
          .delete_if { |credential| credential.id == id }
          .push(provider_credential)
      )
      Services.user_service.update_user!(new_user)
    end
  end
end
