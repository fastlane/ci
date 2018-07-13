require "spec_helper"
require "app/services/dot_keys_variable_service"

describe FastlaneCI::DotKeysVariableService do
  let(:fake_home_path) do
    File.join(FastlaneCI::FastlaneApp.settings.root, "spec/fixtures/files/")
  end

  let (:fake_keys_file) do
    File.join(fake_home_path, ".fastlane/ci/.keys")
  end

  before(:each) do
    allow(Dir).to receive(:home).and_return(fake_home_path)
  end

  subject do
    FastlaneCI::DotKeysVariableService.new
  end

  describe "#write_keys_file!" do
    it "writes keys to keys file and reloads environment variables" do
      allow_any_instance_of(FastlaneCI::KeysWriter).to receive(:new).with(
        path: fake_keys_file, locals: new_environment_variables
      )
      allow_any_instance_of(FastlaneCI::KeysWriter).to receive(:write!)
      expect(subject).to receive(:reload_dot_env!)

      subject.write_keys_file!(locals: locals_parameters)
    end
  end

  describe "#reload_dot_env" do
    it "Updates the `ENV`, and resets services depending on environment variables" do
      expect(ENV).to receive(:update)
      expect(FastlaneCI::Services).to receive(:reset_services!)

      subject.reload_dot_env!
    end
  end

  describe "#all_dot_variables_non_nil?" do
    it "returns `true` if all environment variables are non-`nil`, and non-'empty'" do
      # Environment variables are set in the `stub_dot_keys` method called in the `spec_helper.rb` file
      expect(subject.all_dot_variables_non_nil?).to be(true)
    end

    it "returns `false` if an environment variable is `nil`" do
      allow_any_instance_of(
        FastlaneCI::DotKeysVariables
      ).to receive(:all).and_return(environment_variables.merge(encryption_key: nil))

      expect(subject.all_dot_variables_non_nil?).to be(false)
    end

    it "returns `false` if an environment variable is 'empty'" do
      allow_any_instance_of(
        FastlaneCI::DotKeysVariables
      ).to receive(:all).and_return(environment_variables.merge(encryption_key: ""))

      expect(subject.all_dot_variables_non_nil?).to be(false)
    end
  end

  describe "#keys_file_path" do
    it "has correct file path" do
      expect(subject.keys_file_path).to eq(fake_keys_file)
    end
  end

  describe "#keys_file_path_relative_to_home" do
    it "has correct file path" do
      expect(subject.keys_file_path_relative_to_home).to eq("~/.fastlane/ci/.keys")
    end
  end

  def locals_parameters
    return {
      "encryption_key": "some_new_key",
      "ci_user_password": nil,
      "ci_user_api_token": nil,
      "repo_url": "https://github.com/user_name/new_repo_name",
      "initial_onboarding_user_api_token": nil
    }
  end

  def new_environment_variables
    return {
      encryption_key: "some_new_key",
      ci_user_password: "ci_user_password",
      ci_user_api_token: nil,
      repo_url: "https://github.com/user_name/new_repo_name",
      initial_onboarding_user_api_token: "initial_onboarding_user_api_token"
    }
  end
end
