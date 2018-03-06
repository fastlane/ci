require File.expand_path("../../spec_helper.rb", __FILE__)
require File.expand_path("../../../services/test_runner_service.rb", __FILE__)

describe FastlaneCI::TestRunnerService do
  # Will not cause an exception to be raised in `subject.run` because the project
  # constructor is given a 'repo_config' attribute
  let (:good_project) do
    FastlaneCI::Project.new(
      repo_config: git_repo,
      enabled: true,
      project_name: "fake_project",
      lane: "fake_lane"
    )
  end

  subject do
    FastlaneCI::TestRunnerService.new(
      project: good_project,
      sha: SecureRandom.uuid,
      github_service: double("GithubService", set_build_status!: nil)
    )
  end

  before(:each) do
    stub_file_io
    stub_git_repos
    stub_services
  end

  describe "#run" do
    let (:builds) do
      (1..3).map do |index|
        FastlaneCI::Build.new(
          project: good_project,
          number: index,
          status: :pending,
          timestamp: Time.now,
          duration: -1,
          sha: SecureRandom.uuid
        )
      end
    end

    before(:each) do
      FastlaneCI::BuildService.any_instance.stub(:list_builds).and_return(builds)
      subject.should_receive(:update_build_status!).twice

      # Don't execute build command
      TTY::Command.any_instance.stub(:run)
    end

    context "success" do
      before(:each) { allow(subject).to receive(:project).and_return(good_project) }

      it "Updates the current build and sets the status to 'success' when a build passes" do
        expect { subject.run }.to change { subject.current_build }.from(nil)
      end

      after(:each) do
        expect(subject.current_build.status).to eq(:success)

        # Build should be incremented by 1
        expect(subject.current_build.number).to eq(4)
      end
    end
  end

  describe "#rerun" do
    let (:build) do
      FastlaneCI::Build.new(
        project: good_project,
        number: 1,
        status: :pending,
        timestamp: Time.now,
        duration: -1,
        sha: SecureRandom.uuid
      )
    end

    before (:each) do
      subject.should_receive(:update_build_status!).twice

      # Don't execute build command
      TTY::Command.any_instance.stub(:run)
    end

    context "success" do
      before(:each) { allow(subject).to receive(:project).and_return(good_project) }

      it "Updates the current build and sets the status to 'success' when a build passes" do
        expect { subject.run }.to change { subject.current_build }.from(nil)
      end

      after(:each) do
        expect(subject.current_build.status).to eq(:success)

        # Build should not be incremented by 1
        expect(subject.current_build.number).to eq(build.number)
      end
    end
  end
end
