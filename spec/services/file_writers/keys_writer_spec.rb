require "spec_helper"
require "app/services/file_writers/keys_writer"

describe FastlaneCI::KeysWriter do
  before(:each) do
    stub_file_io
  end

  let(:fixtures_path) do
    File.join(
      FastlaneCI::FastlaneApp.settings.root,
      "spec/fixtures/files/templates"
    )
  end

  let(:template_path) do
    File.join(fixtures_path, "keys_template.txt")
  end

  let(:template_string) do
    File.read(template_path)
  end

  subject do
    described_class.new(
      path: template_path,
      locals: {
        encryption_key: "key",
        ci_user_password: "ci_user_password",
        ci_user_api_token: "bot_api_token",
        repo_url: "https://github.com/user/repo",
        initial_onboarding_user_api_token: "initial_onboarding_user_api_token"
      }
    )
  end

  describe "#write!" do
    it "opens and writes the `file_template` to the `path`, with the correct `locals`" do
      expect(File)
        .to receive(:write)
        .with(template_path, template_string)

      subject.write!
    end
  end
end
