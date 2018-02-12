require_relative "code_hosting_service"
require "octokit"

module FastlaneCI
  # Data source that interacts with GitHub
  # TODO: should probably be renamed GitHubService
  class GitHubService < CodeHostingService

    # The email is actually optional for API access
    # However we ask for the email on login, as we also plan on doing commits for the user
    # and this way we can make sure to configure things properly for git to use the email
    attr_accessor :provider_credential

    def initialize(provider_credential: nil)
      self.provider_credential = provider_credential
      # TODO: Remove the ENV["INITIAL_CLONE_API_TOKEN"] from here, this was just for testing
      @_client = Octokit::Client.new(access_token: ENV["INITIAL_CLONE_API_TOKEN"] || provider_credential.api_token)
      Octokit.auto_paginate = true # TODO: just for now, we probably should do smart pagination in the future
    end

    def client
      @_client
    end

    def session_valid?
      client.login.to_s.length > 0
    rescue StandardError
      false
    end

    def username
      client.login
    end

    # TODO: parse those here or in service layer?
    def repos
      client.repos({}, query: { sort: "asc" })
    end

    # The `target_url`, `description` and `context` parameters are optional
    # @repo [String] Repo URL as string
    def set_build_status!(repo: nil, sha: nil, state: nil, target_url: nil, description: nil, context: nil)
      state = state.to_s

      # Available states https://developer.github.com/v3/repos/statuses/
      available_states = ["error", "failure", "pending", "success"]
      raise "Invalid state '#{state}'" unless available_states.include?(state)

      # We auto receive the SLUG, so that the user of this class can pass a full URL also
      repo = repo.split("/")[-2..-1].join("/")

      # TODO: this will use the user's session, so their face probably appears there
      # As Josh already predicted, we're gonna need a fastlane.ci account also
      # that we use for all non-user actions.
      # This includes scheduled things, commit status reporting and probably more in the future

      if description.nil?
        description = "All green" if state == "success"
        description = "Still running" if state == "pending"

        # TODO: what's the difference?
        description = "Something went wrong" if state == "failure"
        description = "Something went wrong" if state == "error"
      end

      # TODO: Enable once the GitHub token is fixed
      #
      # Full docs for `create_status` over here
      # https://octokit.github.io/octokit.rb/Octokit/Client/Statuses.html
      client.create_status(repo, sha, state, {
        target_url: target_url,
        description: description,
        context: context || "fastlane.ci"
      })
    rescue StandardError => ex
      # TODO: how do we handle GitHub errors
      # In this case `create_status` will cause an exception
      # if the user doesn't have write permission for the repo
      raise ex
    end
  end
end
