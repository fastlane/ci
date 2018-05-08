require "spec_helper"
require "app/services/xcode_manager_service"

describe FastlaneCI::XcodeManagerService do
  let (:xcode_manager_service) { FastlaneCI::XcodeManagerService.new }
  
  describe "#switch_xcode_version!" do
    it "switches the DEVELOPER_DIR ENV variable" do
      path = "/Applications/Xcode.app"
      xcode_manager_service.switch_xcode_version!(xcode_path: path)
      expect(ENV["DEVELOPER_DIR"]).to eq(path)
    end
  end

  describe "#clear_xcode_version!" do
    it "clears the DEVELOPER_DIR ENV variable" do
      ENV["DEVELOPER_DIR"] = "/Applications/Xcode.app"
      xcode_manager_service.clear_xcode_version!
      expect(ENV["DEVELOPER_DIR"]).to eq(nil)
    end
  end
end
