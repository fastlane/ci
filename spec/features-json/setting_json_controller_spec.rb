require "spec_helper"
require "app/features-json/setting_json_controller"

describe FastlaneCI::SettingJSONController do
  let(:app) { described_class.new }
  let(:json) { JSON.parse( last_response.body) }
  
  before do
    header("Authorization", bearer_token)
  end

  describe "GET /data/settings" do
    it "returns the settings" do
      get("/data/settings")
      expect(last_response).to be_ok
      expect(json).to be_a(Array)
      all_settings = json

      expect(all_settings.count).to eq(FastlaneCI::AvailableSettings.available_settings.count)

      all_settings.each do |setting|
        expect(setting).to be_a(Hash)
        expect(setting["key"].length).to be > 0
        expect(setting["description"].length).to be > 0

        expect(setting.key?("default_value")).to eq(true)
        expect(setting.key?("value")).to eq(true)
      end
    end
  end

  describe "POST /data/settings/:setting_key" do
    
    it "returns an error if key doesn't exist" do
      non_existent_key = "non_existent_key"
      post("/data/settings/#{non_existent_key}")
      # expect(last_response).to_not be_ok # TODO: use right exit code
      expect(json["error"].to_s.length).to be > 0
      expect(json["error"]).to eq("`non_existent_key` not found.")
    end
  end
end
