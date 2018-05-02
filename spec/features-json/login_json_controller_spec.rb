require "spec_helper"
require "app/features-json/login_json_controller"
require "app/services/onboarding_service"
require "app/services/user_service"

describe FastlaneCI::LoginJSONController do
  def app
    described_class
  end
  let(:user) { double("User", id: "some-id") }
  let(:json) { JSON.parse(last_response.body) }

  before do
    allow(FastlaneCI::Services.onboarding_service).to receive(:correct_setup?).and_return(true)
    allow(FastlaneCI::Services.user_service).to receive(:login).and_return(user)
    allow(FastlaneCI.dot_keys).to receive(:encryption_key).and_return("test")
  end

  it "should return a valid JWT token using the global encryption key" do
    post "/api/login", { email: "fastlane", password: "password" }.to_json, { "CONTENT_TYPE" => "application/json" }
    expect(last_response).to be_ok
    expect(json).to have_key("token")
  end
end
