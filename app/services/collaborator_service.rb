# frozen_string_literal: true

module FastlaneCI
  # Manages bot user collaboration on user's GitHub fastlane.ci projects.
  class CollaboratorService
    include FastlaneCI::Logging
    include FastlaneCI::GitHubHandler

    # An octokit client authenticated with the onboarding user's API token
    #
    # @return [Octokit::Client]
    attr_reader :onboarding_user_client

    # An octokit client authenticated with the bot user's API token
    #
    # @return [Octokit::Client]
    attr_reader :bot_user_client

    # Instantiates new `CollaboratorService` class
    #
    # @param  [ProviderCredential] provider_credential
    def initialize(provider_credential:)
      @onboarding_user_client = Octokit::Client.new(access_token: provider_credential.api_token)
      @bot_user_client = Octokit::Client.new(access_token: FastlaneCI.dot_keys.ci_user_api_token)
    end

    # Adds the bot user as a collaborator to the GitHub repository corresponding to the given `repo_shortform`
    #
    # @return [Boolean] If the user was added successfully
    def add_bot_user_as_collaborator(repo_shortform:)
      already_exists = bot_user_collaborator_on_project?(repo_shortform: repo_shortform)

      if already_exists
        logger.debug("Bot user is already a collaborator to #{repo_shortform}, not adding as collaborator.")
        return true
      end

      logger.debug("Adding bot user as collaborator to #{repo_shortform}.")

      invitation_id = invite_bot_user_to_repository!(repo_shortform: repo_shortform)

      if !invitation_id.nil?
        return accept_invitation_to_repository_as_bot_user(
          repo_shortform: repo_shortform,
          invitation_id: invitation_id
        )
      else
        raise "Could not add bot user as a collaborator. Invitation was not sent to collaborate on #{repo_shortform}."
      end
    end

    # Checks if the bot user is a collaborator to a given `project_name`
    #
    # @param  [String] repo_shortform: The name of the repository to check if the bot user is a collaborator on
    # @return [Boolean] If the bot user has access to the given project
    def bot_user_collaborator_on_project?(repo_shortform:)
      github_action(onboarding_user_client) { |c| c.collaborator?(repo_shortform, bot_user_login) }
    end

    private

    # Adds the bot user as a collaborator to the GitHub repository corresponding to the given `repo_shortform`
    #
    # @param  [String] repo_shortform: The name of the repository to invite the bot user to collaborate on
    # @return [Integer] `invitation.id`
    def invite_bot_user_to_repository!(repo_shortform:)
      logger.debug("Adding the bot user as a collaborator for #{repo_shortform}.")

      return github_action(onboarding_user_client) do |client|
        invitation = client.invite_user_to_repository(repo_shortform, bot_user_login)

        if invitation
          logger.debug("Added bot user as collaborator for #{repo_shortform}.")
          invitation.id
        else
          logger.error("ERROR: Couldn't add bot user as collaborator for #{repo_shortform}.")
          nil
        end
      end
    end

    # Accepts the invitation to the fastlane.ci repository as the bot user
    #
    # @param  [String] repo_shortform: The name of the repository to accept the bot user's invitation to collaborate
    # @param  [Integer] invitation_id
    # @return [Boolean] `true` if the invitation was successfully accepted
    def accept_invitation_to_repository_as_bot_user(repo_shortform:, invitation_id:)
      logger.debug("Accepting invitation as bot user for #{repo_shortform}.")

      return github_action(bot_user_client) do |client|
        bot_accepted = client.accept_repository_invitation(invitation_id)

        if bot_accepted
          logger.debug("Bot user accepted invitation to #{repo_shortform}.")
        else
          logger.error("ERROR: Bot user didn't accept invitation to #{repo_shortform}.")
        end

        bot_accepted
      end
    end

    # The login of the fastlane.ci bot account
    #
    # @return [String]
    def bot_user_login
      return github_action(bot_user_client, &:login)
    end
  end
end
