require "spec_helper"
require "app/features-json/user_json_controller"
require "app/services/user_service"

describe FastlaneCI::UserJSONController do
  def app
    described_class
  end
  let(:json) { JSON.parse(last_response.body) }

  before do
    allow(FastlaneCI.dot_keys).to receive(:encryption_key).and_return("test")
  end

  describe "/api/user" do
    let(:fake_email) { "email@email.com" }
    before do
      github_client = "github_client"
      expect(Octokit::Client).to receive(:new).and_return(github_client)

      email_entry = "email_entry"
      expect(email_entry).to receive(:primary).and_return(true)
      expect(email_entry).to receive(:email).and_return(fake_email)

      expect(github_client).to receive(:emails).and_return([email_entry])
    end

    it "creates a new user and attach the provider credentials" do
      allow(FastlaneCI::Services.user_service.user_data_source).to receive(:user_exist?).with({ email: fake_email }).and_return(false)

      post "/api/user", { github_token: "github_token", password: "password" }.to_json, { "CONTENT_TYPE" => "application/json" }
      expect(last_response).to be_ok
      expect(json["status"]).to eq("success")
    end

    it "returns an error if the user already exists" do
      allow(FastlaneCI::Services.user_service.user_data_source).to receive(:user_exist?).with({ email: fake_email }).and_return(true)

      post "/api/user", { github_token: "github_token", password: "password" }.to_json, { "CONTENT_TYPE" => "application/json" }

      expect_json_error(
        message: "Error creating new user",
        key: "User.Error",
        status: 400
      )
    end
  end
end
