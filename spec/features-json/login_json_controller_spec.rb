require "spec_helper"
require "app/features-json/login_json_controller"

describe FastlaneCI::LoginJSONController do

  def app() described_class end

  it "should return a valid JWT token using the global encryption key" do
    
    post "/login", { username: "fastlane", password: "password" }.to_json, { "CONTENT_TYPE" => "application/json" }
    
    # TODO: For whatever reason I can't figure out, the response is not what
    # I'm expecting here, so tests are failing.
    expect(last_response).to be_ok
    expect(last_response).to be_json

  end
end