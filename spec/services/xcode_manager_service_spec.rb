require "spec_helper"
require "app/services/xcode_manager_service"

describe FastlaneCI::XcodeManagerService do
  let (:apple_id_email) { "fake@random.com" }
  let (:apple_id_password) { "top_secret" }
  let (:secondary_apple_id_email) { "fake_also@random.com" }

  let (:xcode_manager_service) do
    apple_ids = [
      FastlaneCI::AppleID.new(
        user: apple_id_email,
        password: apple_id_password
      ),
      FastlaneCI::AppleID.new(
        user: secondary_apple_id_email,
        password: "top_secret_also"
      )
    ]

    allow(FastlaneCI::Services.apple_id_service).to receive(:apple_ids).and_return(apple_ids)
    service = FastlaneCI::XcodeManagerService.new(user: apple_id_email)
    allow(service.installer).to receive(:exist?).and_return(true)

    service
  end

  before do
    allow(FastlaneCI.dot_keys).to receive(:encryption_key).and_return("test")
  end

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

  describe "#apple_id" do
    it "allows access to the apple_id" do
      expect(xcode_manager_service.apple_id.user).to eq(apple_id_email)
      expect(xcode_manager_service.apple_id.password).to eq(apple_id_password)
    end
  end

  describe "#use_apple_id" do
    # TODO: enable test again once we decide on Apple ID flow
    # it "raises an exception if Apple ID isn't available" do
    #   unavailable_apple_id = "someonewhodoesntexist@random.com"
    #   expect do
    #     xcode_manager_service.use_apple_id(user: unavailable_apple_id)
    #   end.to raise_error("No registered Apple ID found with user #{unavailable_apple_id}, make sure to add your Apple account to fastlane.ci")
    # end

    it "properly switches the Apple ID if it is available" do
      xcode_manager_service.use_apple_id(user: secondary_apple_id_email)
      expect(xcode_manager_service.apple_id.user).to eq(secondary_apple_id_email)
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

  describe "#apple_id_credentials_block" do
    it "properly fills it all required ENV variables without polluting the parent" do
      expect(ENV["XCODE_INSTALL_USER"]).to eq(nil)
      expect(ENV["XCODE_INSTALL_PASSWORD"]).to eq(nil)

      xcode_manager_service.apple_id_credentials_block do
        expect(ENV["XCODE_INSTALL_USER"]).to eq(apple_id_email)
        expect(ENV["XCODE_INSTALL_PASSWORD"]).to eq(apple_id_password)
      end

      expect(ENV["XCODE_INSTALL_USER"]).to eq(nil)
      expect(ENV["XCODE_INSTALL_PASSWORD"]).to eq(nil)
    end

    it "doesn't swallow exceptions happening in that block & clears ENV variables" do
      expect(ENV["XCODE_INSTALL_USER"]).to eq(nil)
      expect(ENV["XCODE_INSTALL_PASSWORD"]).to eq(nil)

      expect do
        xcode_manager_service.apple_id_credentials_block do
          raise "yolo"
        end
      end.to raise_error("yolo")
    end
  end

  describe "#installing_xcode_versions" do
    it "returns an empty hash on a new service init" do
      expect(xcode_manager_service.installing_xcode_versions).to eq({})
    end

    it "returns a hash with Xcode versions if installations are in progress" do
      version_to_install = Gem::Version.new("8.1")

      expect(xcode_manager_service.xcode_queue).to receive(:add_task_async).and_return(nil)

      xcode_manager_service.install_xcode!(version: version_to_install)
      expect(xcode_manager_service.installing_xcode_versions).to eq({
        version_to_install => 0
      })
    end

    it "raises an exception if installation is already in progress" do
      version_to_install = Gem::Version.new("8.1")

      xcode_manager_service.installing_xcode_versions = {
        version_to_install => 50
      }

      expect do
        xcode_manager_service.install_xcode!(version: version_to_install)
      end.to raise_error("Xcode version 8.1 is already being downloaded... Download couldn't be started")
    end
  end
end
