require "spec_helper"
require "app/services/collaborator_service"

describe FastlaneCI::CollaboratorService do
  let(:user_client) { double("User Client", login: true) }
  let(:bot_client) { double("Bot Client", login: true) }
  let(:invitation) { double("Invitation", id: "12345678") }
  let(:repo_shortform) { "username/reponame" }

  let(:service) do
    FastlaneCI::CollaboratorService.new(provider_credential: double("Credentials", api_token: "abc123"))
  end

  before do
    allow(service).to receive(:onboarding_user_client).and_return(user_client)
    allow(service).to receive(:bot_user_client).and_return(bot_client)
  end

  describe "#add_bot_user_as_collaborator!" do
    it "adds a bot user as a collaborator" do
      expect(user_client).to receive(:collaborator?).and_return(false)
      expect(user_client).to receive(:invite_user_to_repository).and_return(invitation)
      expect(bot_client).to receive(:accept_repository_invitation).with(invitation.id)

      service.add_bot_user_as_collaborator!(repo_shortform: repo_shortform)
    end
  end

  describe "#bot_user_collaborator_on_project?" do
    context "bot user is a collaborator" do
      it "checks if a bot user is a collaborator on a given project" do
        expect(user_client).to receive(:collaborator?).and_return(true)
        expect(service.bot_user_collaborator_on_project?(repo_shortform: repo_shortform)).to be(true)
      end
    end

    context "bot user is not a collaborator" do
      it "checks if a bot user is a collaborator on a given project" do
        expect(user_client).to receive(:collaborator?).and_return(false)
        expect(service.bot_user_collaborator_on_project?(repo_shortform: repo_shortform)).to be(false)
      end
    end
  end
end
