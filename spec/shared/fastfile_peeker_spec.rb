require "fastfile_parser"
require "digest"

require_relative "../stub_helpers"
require_relative "../../app/shared/fastfile_peeker"

module FastlaneCI
  describe FastlaneCI::FastfilePeeker do
    let(:file_path) do
      File.join(FastlaneCI::FastlaneApp.settings.root, "spec/fixtures/files/")
    end

    let(:provider_credential) do
      return "credential"
    end

    let(:repo_config) do
      return GitHubRepoConfig.new(id: nil,
                                  git_url: nil,
                                  description: nil,
                                  name: "name",
                                  full_name: "repo/user",
                                  hidden: false)
    end

    let(:notification_service) do
      return "notification_service"
    end

    before(:each) do
      allow(provider_credential).to receive(:type).and_return("github")
      allow(provider_credential).to receive(:api_token).and_return("tacos")

      stub_file_io
      stub_git_repos
      stub_services
    end

    let (:repo_1_file_path) do
      File.join(file_path, "fastfile_peeker", "repo_stub_1")
    end

    let (:repo_1_fastfile_path) do
      File.join(repo_1_file_path, "fastlane", "Fastfile")
    end

    describe "#fastfile_from_repo" do
      it "returns the Fastfile for a given repo" do
        allow_any_instance_of(FastlaneCI::GitRepo).to receive(:checkout_branch).with({ branch: "master" }).and_return(nil)
        allow_any_instance_of(FastlaneCI::GitRepo).to receive(:local_folder).and_return(
          File.join(repo_1_file_path)
        )
        peeker = FastlaneCI::FastfilePeeker.new(provider_credential: provider_credential, notification_service: notification_service)
        fastfile = peeker.fastfile_from_repo(repo_config: repo_config, branch: "master", sha: nil)
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

    describe "#fastfile" do
      it "search Fastfile on GitHub, if found do not search Fastfile in local" do
        peeker = FastlaneCI::FastfilePeeker.new(provider_credential: provider_credential, notification_service: notification_service)
        allow(peeker).to receive(:fastfile_from_github).and_return(Fastlane::FastfileParser.new(path: repo_1_fastfile_path))
        allow(peeker).to receive(:fastfile_from_repo).and_return(nil)

        peeker.fastfile(repo_config: repo_config, sha_or_branch: "master")
        expect(peeker).to have_received(:fastfile_from_github)
        expect(peeker).not_to(have_received(:fastfile_from_repo))
      end

      it "search Fastfile on GitHub, if not found search Fastfile in local" do
        peeker = FastlaneCI::FastfilePeeker.new(provider_credential: provider_credential, notification_service: notification_service)
        allow(peeker).to receive(:fastfile_from_github).and_return(nil)
        allow(peeker).to receive(:fastfile_from_repo).and_return(nil)

        peeker.fastfile(repo_config: repo_config, sha_or_branch: "master")
        expect(peeker).to have_received(:fastfile_from_github)
        expect(peeker).to have_received(:fastfile_from_repo)
      end

      it "returns Fastlane/Fastfile path, if exists" do
        fastfile_path = FastfileFinder.find_prioritary_fastfile_path(paths:
            ["path/Fastlane/Fastfile",
             "path/Fastlane/TestFastfile",
             "fastfile",
             "Fastlane/Fastfile"])

        expect(fastfile_path).to eql("Fastlane/Fastfile")
      end

      it "returns any Fastfile path if Fastlane/Fastfile does not exist" do
        fastfile_path = FastfileFinder.find_prioritary_fastfile_path(paths:
                                                                         ["path/Fastlane/Fastfile",
                                                                          "path/Fastlane/TestFastfile",
                                                                          "fastfile"])

        expect(fastfile_path).not_to(be(nil))
      end

      it "returns nil if there are no Fastfile" do
        fastfile_path = FastfileFinder.find_prioritary_fastfile_path(paths:
                                                                         ["path/Fastlane/Fastfiles",
                                                                          "path/Fastlane/TestFastfile",
                                                                          "Fastlane/BackupFastlane"])

        expect(fastfile_path).to(be(nil))
      end
    end
  end
end
