require_relative "../../shared/models/provider_credential"
module FastlaneCI
  # Abstract base class for all code hosting data services
  class CodeHostingService
    def initialize(provider_credential: nil)
      not_implemented(__method__)
    end

    def session_valid?
      not_implemented(__method__)
    end

    # FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES
    def provider_type
      not_implemented(__method__)
    end

    def repos
      not_implemented(__method__)
    end

    def access_to_repo?(repo_url: nil)
      not_implemented(__method__)
    end
  end
end
