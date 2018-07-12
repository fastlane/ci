require "spec_helper"
require "app/features-json/setting_json_controller"

describe FastlaneCI::SettingJSONController do
  let(:app) { described_class.new }
  let(:json) { JSON.parse(last_response.body) }

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
    it "successfully updates the setting" do
      metrics_key = "metrics_enabled"
      new_value = "true"

      setting = FastlaneCI::Services.setting_service.find_setting(setting_key: metrics_key.to_sym)
      setting.value = "false"
      FastlaneCI::Services.setting_service.update_setting!(setting: setting)
      expect(FastlaneCI::Services.setting_service.find_setting(setting_key: metrics_key.to_sym).value).to eq("false")

      post("/data/settings/#{metrics_key}?value=#{new_value}")
      expect(json).to eq({ "status" => "success" })

      expect(FastlaneCI::Services.setting_service.find_setting(setting_key: metrics_key.to_sym).value).to eq("true")
    end

    it "returns an error if key doesn't exist" do
      non_existent_key = "non_existent_key"
      post("/data/settings/#{non_existent_key}")

      expect_json_error(
        message: "`non_existent_key` not found.",
        key: "InvalidParameter.KeyNotFound",
        status: 404
      )
    end
  end

  describe "DELETE /data/settings/:setting_key" do
    it "works" do
      metrics_key = "metrics_enabled"
      setting = FastlaneCI::Services.setting_service.find_setting(setting_key: metrics_key.to_sym)
      setting.value = "true"
      FastlaneCI::Services.setting_service.update_setting!(setting: setting)

      delete("/data/settings/#{metrics_key}")
      expect(json).to eq({ "status" => "success" })

      expect(FastlaneCI::Services.setting_service.find_setting(setting_key: metrics_key.to_sym).value).to eq(nil)
    end

    it "returns an error if key can't be found" do
      non_existent_key = "non_existent_key"
      delete("/data/settings/#{non_existent_key}")

      expect_json_error(
        message: "`non_existent_key` not found.",
        key: "InvalidParameter.KeyNotFound",
        status: 404
      )
    end
  end
end
