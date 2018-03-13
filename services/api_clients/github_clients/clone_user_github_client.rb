# frozen_string_literal: true

require_relative "../api_client"

module FastlaneCI
  # An injectable module for easy access to the GitHub API
  module CloneUserGitHubClient
    extend APIClient

    # Returns an GitHub API client object with the clone user credentials
    #
    # @return [Octokit::Client]
    def client
      @client ||= Octokit::Client.new(
        access_token: FastlaneCI.env.clone_user_api_token,
        api_endpoint: "https://api.github.com/"
      )
    end
  end
end
