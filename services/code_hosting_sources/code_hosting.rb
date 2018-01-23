require_relative "../../shared/models/provider_credential"
module FastlaneCI
  # Abstract base class for all code hosting data sources
  class CodeHosting
    def session_valid?
      not_implemented(__method__)
    end

    # FastlaneCI::ProviderCredential::PROVIDER_TYPES
    def provider_type
      not_implemented(__method__)
    end

    def repos
      not_implemented(__method__)
    end
  end
end
