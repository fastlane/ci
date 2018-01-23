require "json"
module FastlaneCI
  # base class for all providers, see GitHubProvider as an example
  class ProviderCredential
    # we'll transform this list so the enum can be sym => string, and string => string
    simple_provider_types = {
      github: "github"
    }

    doubled_types = {}
    simple_provider_types.each do |key, value|
      doubled_types[key] = value
      doubled_types[key.to_s] = value
    end

    PROVIDER_TYPES = doubled_types.freeze

    attr_accessor :type # must be defined in sub class
    attr_accessor :ci_user # user associated with this provider
    attr_accessor :provider_name # MUST be unique, not a problem right now with just supporting GitHub

    def type
      not_implemented(__method__)
    end

    def provider_name
      not_implemented(__method__)
    end

    def initialize
    end
  end
end
