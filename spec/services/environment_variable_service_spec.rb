require "spec_helper"
require "app/services/environment_variable_service"

describe FastlaneCI::EnvironmentVariableService do
  describe "#keys_file_path" do
    before(:each) do
      allow(Dir).to receive(:home).and_return("/path/to/home")
    end
    it "has correct file path" do
      expect(FastlaneCI::EnvironmentVariableService.new.keys_file_path).to eq("/path/to/home/.fastlane/ci/.keys")
    end
  end

  describe "#keys_file_path_relative_to_home" do
    it "has correct file path" do
      expect(FastlaneCI::EnvironmentVariableService.new.keys_file_path_relative_to_home).to eq("~/.fastlane/ci/.keys")
    end
  end
end
