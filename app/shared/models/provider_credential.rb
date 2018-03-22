require "json"
module FastlaneCI
  # base class for all provider credentials, see GitHubProviderCredential as an example
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

    PROVIDER_CREDENTIAL_TYPES = doubled_types.freeze

    attr_accessor :id
    attr_accessor :ci_user # user associated with this provider

    attr_writer :type # must be defined in sub class
    attr_writer :email # must be defined in sub class
    attr_writer :full_name # full name that the user intends to be in the commit author
    attr_writer :provider_name # MUST be unique, not a problem right now with just supporting GitHub
    attr_writer :remote_host # usually github.com

    def type
      not_implemented(__method__)
    end

    def email
      not_implemented(__method__)
    end

    def provider_name
      not_implemented(__method__)
    end

    def full_name
      not_implemented(__method__)
    end

    def remote_host
      not_implemented(__method__)
    end

    def initialize
      self.id = SecureRandom.uuid
    end
  end
end
