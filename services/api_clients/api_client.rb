# frozen_string_literal: true

module FastlaneCI
  # Injectable ApiClient module exposing APIs for the CI user, and clone users
  #
  # @abstract
  module APIClient
    # Returns an API client object with the CI user credentials
    #
    # @abstract
    def client
      not_implemented(__method__)
    end
  end
end
