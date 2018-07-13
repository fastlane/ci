require "spec_helper"
require "app/services/configuration_repository_service"

describe FastlaneCI::ConfigurationRepositoryService do
  let(:user_client) { double("User Client", login: true) }
  let(:bot_client) { double("Bot Client", login: true) }
  let(:service) do
    FastlaneCI::ConfigurationRepositoryService.new(provider_credential: double("Credentials", api_token: "abc123"))
  end
  let(:collaborator_service) do
    FastlaneCI::CollaboratorService.new(provider_credential: double("Credentials", api_token: "abc123"))
  end

  before do
    allow(service).to receive(:onboarding_user_client).and_return(user_client)
    allow(service).to receive(:bot_user_client).and_return(bot_client)
    allow(FastlaneCI::Services).to receive(:collaborator_service).and_return(collaborator_service)
  end

  describe "#setup_private_configuration_repo" do
    it "creates a config repo, if one it doesn't exist" do
      allow(collaborator_service).to receive(:add_bot_user_as_collaborator!)
      allow(service).to receive(:create_remote_configuration_files!)

      expect(service).to receive(:configuration_repository_exists?).and_return(false)
      expect(user_client).to receive(:create_repository).once
      service.setup_private_configuration_repo
    end

    it "creates remote configuration files" do
      allow(service).to receive(:create_private_remote_configuration_repo!)
      allow(collaborator_service).to receive(:add_bot_user_as_collaborator!)
      allow(service).to receive(:serialized_users)

      expect(service).to receive(:create_remote_json_file).with("users.json", any_args)
      expect(service).to receive(:create_remote_json_file).with("projects.json")
      expect(service).to receive(:create_remote_json_file).with("environment_variables.json")
      service.setup_private_configuration_repo
    end
  end
end
