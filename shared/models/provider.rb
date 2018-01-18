require "json"
module FastlaneCI
  # base class for all providers, see GitHubProvider as an example
  class Provider
    # we'll transform this list so the enum can be sym => string, and string => string
    simple_provider_types = {
      github: "github"
    }

    PROVIDER_TYPES = {}
    simple_provider_types.each do |key, value|
      PROVIDER_TYPES[key] = value
      PROVIDER_TYPES[key.to_s] = value
    end

    PROVIDER_TYPES = PROVIDER_TYPES.freeze

    attr_accessor :type # must be defined in sub class

    def type
      not_implemented(__method__)
    end

    def initialize
    end
  end
end
