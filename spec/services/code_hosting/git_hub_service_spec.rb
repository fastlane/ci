require "spec_helper"
require "app/services/code_hosting/git_hub_service"

describe FastlaneCI::GitHubService do
  describe ".token_scope_validation_error" do
    before(:each) do
      client_instance = an_instance_of(Octokit::Client)
      allow(Octokit::Client).to receive(:new).and_return(client_instance)
      allow(client_instance).to receive(:scopes).with("invalid_token").and_return(["_unrecognized_scope"])
      allow(client_instance).to receive(:scopes).with("valid_token").and_return(["repo"])
    end
    it "returns validation error properties if token invalid" do
      expect(
        FastlaneCI::GitHubService.token_scope_validation_error("invalid_token")
      ).to eq([["_unrecognized_scope"], "repo"])
    end
    it "returns nil if token valid" do
      expect(FastlaneCI::GitHubService.token_scope_validation_error("valid_token")).to be_nil
    end
  end
end
