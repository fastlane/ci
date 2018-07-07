require "spec_helper"
require "app/shared/models/project"
require "app/workers/check_for_new_commits_on_github_worker"

describe FastlaneCI::CheckForNewCommitsOnGithubWorker do
  # The sample project name.
  let(:project_name) do
    "project-1"
  end

  # The full name for the sample project.
  let(:repo_full_name) do
    "username/#{project_name}"
  end

  # Default to looking at the `master` branch.
  let(:branches) do
    Set.new(%w[master])
  end

  # The `FastlaneCI::Project` associated with the builds.
  let(:project) do
    FastlaneCI::Project.new(
      {
        id: "b2be5614-b3a0-4aae-a70b-bf3b29a6ccac",
        repo_config: FastlaneCI::GitHubRepoConfig.new(
          git_url: "https://github.com/username/#{project_name}",
          description: "Description for #{project_name}",
          name: project_name,
          full_name: repo_full_name
        ),
        enabled: true,
        project_name: project_name,
        platform: "ios",
        lane: "default",
        artifact_provider: FastlaneCI::LocalArtifactProvider.new,
        job_triggers: []
      }
    )
  end

  # Shas for commits that have previously had builds run for them.
  let(:master_prev_run_sha_one) { "acdacfe6-af6e-4190-a627-f85ea4cfa769" }
  let(:master_prev_run_sha_two) { "84793bab-80b8-4141-9398-804a72c73851" }
  let(:patch_1_prev_run_sha_one) { "76023ce3-aaf5-4b31-922f-78086a91095b" }
  let(:patch_1_prev_run_sha_two) { "47ef6f6a-c49d-467b-9c86-620ff1aecadd" }
  let(:patch_2_prev_run_sha_one) { "e51c9638-33b2-4baa-8128-8579809fff16" }
  let(:patch_2_prev_run_sha_two) { "30a9f509-695d-4ce7-8c24-7a71f0c9341a" }

  # Shas for commits that have yet to be run in a build.
  let(:master_unrun_sha) { "2172257e-76f1-4949-b77e-1d7145f0a81d" }
  let(:patch_1_unrun_sha_one) { "9b66974c-23c7-46b8-9db5-d01268823475" }
  let(:patch_1_unrun_sha_two) { "908f5120-6a7b-446d-8460-19211c993652" }

  # Test doubles representing `FastlaneCI::Build`s.
  let(:build_doubles) do
    [
      double("build_0", branch: "master", sha: master_prev_run_sha_one),
      double("build_1", branch: "master", sha: master_prev_run_sha_two),
      double("build_2", branch: "patch-1", sha: patch_1_prev_run_sha_one),
      double("build_3", branch: "patch-1", sha: patch_1_prev_run_sha_two),
      double("build_4", branch: "patch-2", sha: patch_2_prev_run_sha_one),
      double("build_5", branch: "patch-2", sha: patch_2_prev_run_sha_two)
    ]
  end

  # Test doubles representing `Octokit::Client::Commit`s.
  let(:branch_name_to_commits_doubles) do
    {
      # This branch `master`, one of the commits has been enqueued in a build.
      "master" => [
        double("commit_0", sha: master_prev_run_sha_one),
        # Commit containing `sha` that needs to be enqueued in a build.
        double("commit_1", sha: master_unrun_sha)
      ],
      # This branch `patch-1`, none of the commits have been enqueued in builds.
      "patch-1" => [
        # Commit containing `sha` that needs to be enqueued in a build.
        double("commit_2", sha: patch_1_unrun_sha_one),
        # Commit containing `sha` that needs to be enqueued in a build.
        double("commit_3", sha: patch_1_unrun_sha_two)
      ],
      # This branch `patch-2`, all of the commits have been enqueued in builds,
      "patch-2" => [
        double("commit_4", sha: patch_2_prev_run_sha_one),
        double("commit_5", sha: patch_2_prev_run_sha_two)
      ]
    }
  end

  # The `FastlaneCI::CheckForNewCommitsOnGithubWorker` service.
  let(:service) do
    local_credential = provider_credential

    # Must set the `ci_user` backref for these worker tests
    local_credential.ci_user = ci_user

    FastlaneCI::CheckForNewCommitsOnGithubWorker.new(
      provider_credential: local_credential,
      project: project,
      notification_service: notification_service
    )
  end

  # Set default stub values for the service.
  before(:each) do
    service.stub(:branches) { branches }
    service.stub(:builds) { build_doubles }
    service.stub(:repo_full_name) { repo_full_name }
    service.stub(:branch_name_to_commits) { branch_name_to_commits_doubles }
  end

  describe "#filter_branch_name_to_commits_mapping" do
    context "`master` branch only (one unrun sha, one previously run sha)" do
      before(:each) { service.stub(:branches) { Set.new(%w[master]) } }

      it "properly filters out commits where the sha exists in a build" do
        filtered_branch_name_to_commits = service.send(:filter_branch_name_to_commits_mapping)
        filtered_commit_shas = filtered_branch_name_to_commits.values.flatten.map(&:sha)

        # Expectations on hash keys.
        expect(filtered_branch_name_to_commits).to have_key("master")
        expect(filtered_branch_name_to_commits.keys).not_to include("patch-1", "patch-2")

        # Expectations on hash values.
        expect(filtered_commit_shas).to include(master_unrun_sha)
        expect(filtered_commit_shas).not_to include(master_prev_run_sha_one)

        # Sanity check.
        expect(filtered_commit_shas).not_to include(patch_1_unrun_sha_one, patch_1_unrun_sha_two, patch_2_prev_run_sha_one, patch_2_prev_run_sha_two)
      end
    end

    context "`patch-1` branch only (two unrun shas, no previously run shas)" do
      before(:each) { service.stub(:branches) { Set.new(%w[patch-1]) } }

      it "properly filters out commits where the sha exists in a build" do
        filtered_branch_name_to_commits = service.send(:filter_branch_name_to_commits_mapping)
        filtered_commit_shas = filtered_branch_name_to_commits.values.flatten.map(&:sha)

        # Expectations on hash keys.
        expect(filtered_branch_name_to_commits).to have_key("patch-1")
        expect(filtered_branch_name_to_commits.keys).not_to include("master", "patch-2")

        # Expectations on hash values.
        expect(filtered_commit_shas).to include(patch_1_unrun_sha_one, patch_1_unrun_sha_two)

        # Sanity check.
        expect(filtered_commit_shas).not_to include(master_prev_run_sha_one, master_unrun_sha, patch_2_prev_run_sha_one, patch_2_prev_run_sha_two)
      end
    end

    context "`patch-2` branch only (no unrun shas, two previously run shas)" do
      before(:each) { service.stub(:branches) { Set.new(%w[patch-2]) } }

      it "properly filters out commits where the sha exists in a build" do
        filtered_branch_name_to_commits = service.send(:filter_branch_name_to_commits_mapping)
        filtered_commit_shas = filtered_branch_name_to_commits.values.flatten.map(&:sha)

        # Expectations on hash keys.
        expect(filtered_branch_name_to_commits).to have_key("patch-2")
        expect(filtered_branch_name_to_commits.keys).not_to include("master", "patch-1")

        # Expectations on hash values.
        expect(filtered_commit_shas).not_to include(patch_2_prev_run_sha_one, patch_2_prev_run_sha_two)

        # Sanity check.
        expect(filtered_commit_shas).not_to include(master_prev_run_sha_one, master_unrun_sha, patch_1_unrun_sha_one, patch_1_unrun_sha_two)
      end
    end

    context "All three branches (three unrun shas, three previously run shas)" do
      before(:each) { service.stub(:branches) { Set.new(%w[master patch-1 patch-2]) } }

      it "properly filters out commits where the sha exists in a build" do
        filtered_branch_name_to_commits = service.send(:filter_branch_name_to_commits_mapping)
        filtered_commit_shas = filtered_branch_name_to_commits.values.flatten.map(&:sha)

        # Expectations on hash keys.
        expect(filtered_branch_name_to_commits.keys).to include("master", "patch-1", "patch-2")

        # Expectations on hash values.
        expect(filtered_commit_shas).to include(master_unrun_sha, patch_1_unrun_sha_one, patch_1_unrun_sha_two)
        expect(filtered_commit_shas).not_to include(master_prev_run_sha_one, patch_2_prev_run_sha_one, patch_2_prev_run_sha_two)
      end
    end
  end

  describe "#enqueue_new_builds" do
    before(:each) do
      number_of_builds = branch_name_to_commits_doubles.values.flatten.size
      service.should_receive(:create_and_queue_build_task).exactly(number_of_builds).times
    end

    it "enqueues all the new builds properly" do
      service.send(:enqueue_new_builds, branch_name_to_commits_doubles)
    end
  end

  describe "#branch_name_to_builds" do
    context "`master` branch only" do
      before(:each) { service.stub(:branches) { Set.new(%w[master]) } }

      it "Properly creates the hash mapping of branch name to corresponding builds." do
        branch_name_to_builds = service.send(:branch_name_to_builds)
        filtered_commit_shas = branch_name_to_builds.values.flatten.map(&:sha)

        # Expectations on hash keys.
        expect(branch_name_to_builds).to have_key("master")
        expect(branch_name_to_builds.keys).not_to include("patch-1", "patch-2")

        # Expectations on hash values.
        expect(filtered_commit_shas).to include(master_prev_run_sha_one, master_prev_run_sha_two)

        # NOTE: This shouldn't mapping include the commit shas.
        expect(filtered_commit_shas).not_to include(master_unrun_sha)
      end
    end

    context "`patch-1` branch only" do
      before(:each) { service.stub(:branches) { Set.new(%w[patch-1]) } }

      it "Properly creates the hash mapping of branch name to corresponding builds." do
        branch_name_to_builds = service.send(:branch_name_to_builds)
        filtered_commit_shas = branch_name_to_builds.values.flatten.map(&:sha)

        # Expectations on hash keys.
        expect(branch_name_to_builds).to have_key("patch-1")
        expect(branch_name_to_builds.keys).not_to include("master", "patch-2")

        # Expectations on hash values.
        expect(filtered_commit_shas).to include(patch_1_prev_run_sha_one, patch_1_prev_run_sha_two)

        # NOTE: This shouldn't mapping include the commit shas.
        expect(filtered_commit_shas).not_to include(patch_1_unrun_sha_one, patch_1_unrun_sha_two)
      end
    end

    context "`patch-2` branch only" do
      before(:each) { service.stub(:branches) { Set.new(%w[patch-2]) } }

      it "Properly creates the hash mapping of branch name to corresponding builds." do
        branch_name_to_builds = service.send(:branch_name_to_builds)
        filtered_commit_shas = branch_name_to_builds.values.flatten.map(&:sha)

        # Expectations on hash keys.
        expect(branch_name_to_builds).to have_key("patch-2")
        expect(branch_name_to_builds.keys).not_to include("master", "patch-1")

        # Expectations on hash values.
        expect(filtered_commit_shas).to include(patch_2_prev_run_sha_one, patch_2_prev_run_sha_two)
      end
    end
  end
end
