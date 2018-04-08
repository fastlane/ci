require "spec_helper"
require "app/services/code_hosting/git_hub_service"

describe FastlaneCI::GitHubService do
  describe ".token_scope_validation_error" do
    context "invalid_token" do
      before(:each) do
        client_instance = an_instance_of(Octokit::Client)
        allow(Octokit::Client).to receive(:new).with(access_token: "invalid_token").and_return(client_instance)
        allow(client_instance).to receive(:scopes).and_return(["_unrecognized_scope"])
      end

      it "returns validation error properties if token invalid" do
        expect(FastlaneCI::GitHubService.token_scope_validation_error("invalid_token")).to eq([["_unrecognized_scope"], "repo"])
      end
    end

    context "valid token" do
      before(:each) do
        client_instance = an_instance_of(Octokit::Client)
        allow(Octokit::Client).to receive(:new).with(access_token: "valid_token").and_return(client_instance)
        allow(client_instance).to receive(:scopes).and_return(["repo"])
      end

      it "returns nil if token valid" do
        expect(FastlaneCI::GitHubService.token_scope_validation_error("valid_token")).to be_nil
      end
    end
  end
end
