require "spec_helper"
require "app/shared/models/build"
require "app/services/data_sources/json_build_data_source"

describe FastlaneCI::JSONBuildDataSource do
  before(:each) do
    stub_file_io
    stub_git_repos
    stub_services
  end

  project_ids = %w[
    4ebdf02f-01cc-4f27-9a48-cc5471e440c
    3288c136-e62b-495f-acbf-444bc2017135
  ]

  # Create project-specific variables to use in following unit tests.
  project_ids.each.with_index do |uuid, index|
    let(:"project_#{index}_id") do
      uuid
    end

    let (:"project_#{index}_builds_file_path") do
      project_id = public_send("project_#{index}_id")
      File.join(fixture_path, "projects", project_id, "builds")
    end

    let(:"project_#{index}_number_of_builds") do
      builds_file_path = public_send("project_#{index}_builds_file_path")
      Dir["#{builds_file_path}/*"].size
    end

    let(:"project_#{index}") do
      project_id = public_send("project_#{index}_id")
      name       = "project-#{index}"
      full_name  = "username/#{full_name}"

      FastlaneCI::Project.new(
        id: project_id,
        repo_config: FastlaneCI::GitHubRepoConfig.new(
          git_url: "https://github.com/#{full_name}",
          description: "Project1",
          name: name,
          full_name: full_name
        ),
        enabled: true,
        project_name: name,
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

    let(:"project_#{index}_new_build") do
      project          = public_send("project_#{index}")
      number_of_builds = public_send("project_#{index}_number_of_builds")

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
  end

  subject { described_class.create(fixture_path) }

  describe "#list_builds" do
    context "project_0" do
      let(:builds) { subject.list_builds(project: project_0) }

      it "lists builds for a particular project" do
        expect(builds).to all(be_an(FastlaneCI::Build))
      end

      it "lists all builds for a particular project" do
        expect(builds.size).to be(project_0_number_of_builds)
      end

      it "builds are aggregated by project" do
        build_ids = builds.map(&:project).map(&:id)
        expect(build_ids).to all(be == project_0_id)
      end
    end

    context "project_1" do
      let(:builds) { subject.list_builds(project: project_1) }

      it "lists builds for a particular project" do
        expect(builds).to all(be_an(FastlaneCI::Build))
      end

      it "lists all builds for a particular project" do
        expect(builds.size).to be(project_1_number_of_builds)
      end

      it "builds are aggregated by project" do
        build_ids = builds.map(&:project).map(&:id)
        expect(build_ids).to all(be == project_1_id)
      end
    end
  end

  describe "#pending_builds" do
    context "project_0" do
      let(:pending_builds) { subject.pending_builds(project: project_0) }

      it "builds are aggregated by project" do
        build_ids = pending_builds.map(&:project).map(&:id)
        expect(build_ids).to all(be == project_0_id)
      end

      it "lists only pending builds" do
        build_statuses = pending_builds.map(&:status)
        expect(build_statuses).to all(be == "pending")
      end
    end

    context "project_1" do
      let(:pending_builds) { subject.pending_builds(project: project_1) }

      it "builds are aggregated by project" do
        build_ids = pending_builds.map(&:project).map(&:id)
        expect(build_ids).to all(be == project_1_id)
      end

      it "lists only pending builds" do
        build_statuses = pending_builds.map(&:status)
        expect(build_statuses).to all(be == "pending")
      end
    end
  end

  describe "#add_build!" do
    context "project_0" do
      it "creates a new JSON build file" do
        new_build_number = project_0_number_of_builds + 1
        new_build_path = File.join(project_0_builds_file_path, "#{new_build_number}.json")
        new_serialized_build = JSON.pretty_generate(
          project_0_new_build.to_object_dictionary(ignore_instance_variables: [:@project])
        )

        expect(File).to receive(:write).with(new_build_path, new_serialized_build)
        subject.add_build!(project: project_0, build: project_0_new_build)
      end
    end

    context "project_1" do
      it "creates a new JSON build file" do
        new_build_number = project_1_number_of_builds + 1
        new_build_path = File.join(project_1_builds_file_path, "#{new_build_number}.json")
        new_serialized_build = JSON.pretty_generate(
          project_1_new_build.to_object_dictionary(ignore_instance_variables: [:@project])
        )

        expect(File).to receive(:write).with(new_build_path, new_serialized_build)
        subject.add_build!(project: project_1, build: project_1_new_build)
      end
    end
  end
end
