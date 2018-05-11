require "spec_helper"
require "app/shared/models/build"
require "app/services/data_sources/json_build_data_source"

describe FastlaneCI::JSONBuildDataSource do
  before(:each) do
    stub_file_io
    stub_git_repos
    stub_services
  end

  let(:project_id) { "4ebdf02f-01cc-4f27-9a48-cc5471e440c" }

  let(:project) do
    FastlaneCI::Project.new(
      id: project_id,
      repo_config: FastlaneCI::GitHubRepoConfig.new(
        git_url: "https://github.com/username/fastlane-app",
        description: "Project1",
        name: "fastlane-app",
        full_name: "username/fastlane-app"
      ),
      enabled: true,
      project_name: "fastlane-app",
      platform: "ios",
      lane: "custom_lane",
      artifact_provider: FastlaneCI::LocalArtifactProvider.new,
      job_triggers: [
        FastlaneCI::JobTrigger.new(
          type: "manual",
          branch: "username-patch-1"
        )
      ]
    )
  end

  let(:number_of_builds) { Dir["#{builds_file_path}/*"].size }

  let(:new_build) do
    FastlaneCI::Build.new(
      project: project,
      number: number_of_builds + 1,
      status: :pending,
      timestamp: Time.now.utc,
      duration: -1,
      trigger: FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit],
      git_fork_config: FastlaneCI::GitForkConfig.new(
        sha: SecureRandom.uuid,
        branch: "master",
        clone_url: project.repo_config.git_url
      )
    )
  end

  let (:builds_file_path) do
    File.join(fixture_path, "projects", project_id, "builds")
  end

  subject { described_class.create(fixture_path) }

  describe "#list_builds" do
    let(:builds) { subject.list_builds(project: project) }

    it "lists builds for a particular project" do
      expect(builds).to all(be_an(FastlaneCI::Build))
    end

    it "lists all builds for a particular project" do
      expect(builds.size).to be(number_of_builds)
    end

    it "builds are aggregated by project" do
      build_ids = builds.map(&:project).map(&:id)
      expect(build_ids).to all(be == project_id)
    end
  end

  describe "#pending_builds" do
    let(:pending_builds) { subject.pending_builds(project: project) }

    it "builds are aggregated by project" do
      build_ids = pending_builds.map(&:project).map(&:id)
      expect(build_ids).to all(be == project_id)
    end

    it "lists only pending builds" do
      build_statuses = pending_builds.map(&:status)
      expect(build_statuses).to all(be == "pending")
    end
  end

  describe "#add_build!" do
    it "creates a new JSON build file" do
      expect(File).to receive(:write)
      subject.add_build!(project: project, build: new_build)
    end
  end
end
