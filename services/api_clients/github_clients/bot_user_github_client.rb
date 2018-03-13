# frozen_string_literal: true

require_relative "../api_client"

module FastlaneCI
  # An injectable module for easy access to the GitHub API
  module BotUserGitHubClient
    extend APIClient

    # Returns an GitHub API client object with the CI user credentials
    #
    # @return [Octokit::Client]
    def client
      @client ||= Octokit::Client.new(
        login: FastlaneCI.env.ci_user_email,
        password: FastlaneCI.env.ci_user_password,
        api_endpoint: "https://api.github.com/"
      )
    end
  end
end
