require "fastfile_parser"
require "digest"

require_relative "../../stub_helpers"
require_relative "../../../app/services/fastfile_peeker/fastfile_peeker"

module FastlaneCI
  describe FastlaneCI::FastfilePeeker do
    before(:each) do
      stub_file_io
      stub_git_repos
      stub_services
    end

    let(:file_path) do
      File.join(FastlaneCI::FastlaneApp.settings.root, "spec/fixtures/files/")
    end

    let (:repo_1_file_path) do
      File.join(file_path, "fastfile_peeker", "repo_stub_1")
    end

    describe "#peek" do
      it "returns the FastfileParser for a given repo" do
        allow_any_instance_of(FastlaneCI::GitRepo).to receive(:checkout_branch).with("master").and_return(nil)
        allow_any_instance_of(FastlaneCI::GitRepo).to receive(:local_folder).and_return(
          File.join(repo_1_file_path)
        )
        fastfile = described_class.peek(git_repo: FastlaneCI::GitRepo.new, branch: "master")
        expect(fastfile.all_lanes_flat).to eql(
          { "" => { description: [], actions: [{ action: :fastlane_version, parameters: "1.10.0" },
                                               { action: :default_platform, parameters: :ios }] },
          "something" => { description: [], actions: [{ action: :sigh, parameters: nil }], private: false },
          "ios _before_all_block_" => { description: [], actions: [{ action: :cocoapods, parameters: nil }] },
          "ios beta" => { description: [], actions: [], private: false },
          "android lane1" => { description: [], actions: [], private: false },
          "android lane2" => { description: [], actions: [], private: false } }
        )
      end
    end
  end
end
