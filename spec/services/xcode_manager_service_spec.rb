require "spec_helper"
require "app/services/xcode_manager_service"

describe FastlaneCI::XcodeManagerService do
  before do
    ENV["XCODE_INSTALL_USER"] = "1"
  end

  let (:xcode_manager_service) { FastlaneCI::XcodeManagerService.new }

  describe "#switch_xcode_version!" do
    it "switches the DEVELOPER_DIR ENV variable" do
      path = "/Applications/Xcode.app"
      xcode_manager_service.switch_xcode_version!(xcode_path: path)
      expect(ENV["DEVELOPER_DIR"]).to eq(path)
    end
  end

  describe "#reset_xcode_version!" do
    it "clears the DEVELOPER_DIR ENV variable" do
      ENV["DEVELOPER_DIR"] = "/Applications/Xcode.app"
      xcode_manager_service.reset_xcode_version!
      expect(ENV["DEVELOPER_DIR"]).to eq(nil)
    end
  end

  describe "#current_xcode_path" do
    it "uses the DEVELOPER_DIR ENV variable if provided" do
      path = "/Applications/Xcode9.2.app"
      ENV["DEVELOPER_DIR"] = path
      expect(xcode_manager_service.current_xcode_path).to eq(path)
    end

    it "falls back to `xcode-select -p` if no ENV variable is provided" do
      path = "/Applications/Xcode9.2.app"
      ENV.delete("DEVELOPER_DIR")
      expect(xcode_manager_service).to receive(:xcode_select_p).and_return(path)
      expect(xcode_manager_service.current_xcode_path).to eq(path)
    end

    it "falls back to `xcode-select -p` if DEVELOPER_DIR ENV is provided but empty" do
      path = "/Applications/Xcode9.2.app"
      ENV["DEVELOPER_DIR"] = ""
      expect(xcode_manager_service).to receive(:xcode_select_p).and_return(path)
      expect(xcode_manager_service.current_xcode_path).to eq(path)
    end

    it "automatically removes the `Contents/Developer` from the path" do
      path = "/Applications/Xcode9.2.app"
      ENV.delete("DEVELOPER_DIR")
      expect(xcode_manager_service).to receive(:xcode_select_p).and_return(path + "/Contents/Developer")
      expect(xcode_manager_service.current_xcode_path).to eq(path)
    end
  end

  describe "#installing_xcode_versions" do
    it "returns an empty on a new service init" do
      expect(xcode_manager_service.installing_xcode_versions).to eq([])
    end

    it "returns an array with Xcode versions if installations are in progress" do
      version = Gem::Version.new("8.1")

      expect(xcode_manager_service.xcode_queue).to receive(:add_task_async).and_return(nil)

      xcode_manager_service.install_xcode!(version: version)
      expect(xcode_manager_service.installing_xcode_versions).to eq([version])
    end
  end
end
