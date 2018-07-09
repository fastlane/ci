require "spec_helper"
require "app/workers/check_for_new_prs_on_github_worker"

describe FastlaneCI::CheckForNewPullRequestsOnGithubWorker do
  # The sample project name.
  let(:project_name) do
    "project-1"
  end

  # The full name for the sample project.
  let(:repo_full_name) do
    "username/#{project_name}"
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

  # Test doubles representing `Octokit::Client::PullRequests`s.
  let(:pull_request_doubles) do
    [
      # Pull request containing `current_sha` that needs to be enqueued in a build.
      double(
        "pull_request_0",
        branch: "master",
        clone_url: "https://github.com/#{repo_full_name}",
        current_sha: master_unrun_sha,
        git_ref: nil
      ),
      double(
        "pull_request_1",
        branch: "master",
        clone_url: "https://github.com/#{repo_full_name}",
        current_sha: master_prev_run_sha_one,
        git_ref: nil
      ),
      # Pull request containing `current_sha` that needs to be enqueued in a build.
      double(
        "pull_request_2",
        branch: "patch-1",
        clone_url: "https://github.com/#{repo_full_name}",
        current_sha: patch_1_unrun_sha_one,
        git_ref: nil
      ),
      # Pull request containing `current_sha` that needs to be enqueued in a build.
      double(
        "pull_request_3",
        branch: "patch-1",
        clone_url: "https://github.com/#{repo_full_name}",
        current_sha: patch_1_unrun_sha_two,
        git_ref: nil
      ),
      double(
        "pull_request_4",
        branch: "patch-1",
        clone_url: "https://github.com/#{repo_full_name}",
        current_sha: patch_2_prev_run_sha_one,
        git_ref: nil
      ),
      double(
        "pull_request_5",
        branch: "patch-1",
        clone_url: "https://github.com/#{repo_full_name}",
        current_sha: patch_2_prev_run_sha_two,
        git_ref: nil
      )
    ]
  end

  # The `FastlaneCI::CheckForNewPullRequestsOnGithubWorker` service.
  let(:service) do
    local_credential = provider_credential

    # Must set the `ci_user` backref for these worker tests
    local_credential.ci_user = ci_user

    FastlaneCI::CheckForNewPullRequestsOnGithubWorker.new(
      provider_credential: local_credential,
      project: project,
      notification_service: notification_service
    )
  end

  # Set default stub values for the service.
  before(:each) do
    service.stub(:builds) { build_doubles }
    service.stub(:repo_full_name) { repo_full_name }
    service.stub_chain(:github_service, :open_pull_requests).with(repo_full_name: repo_full_name) { pull_request_doubles }
  end

  describe "#filter_pull_requests_with_commit_shas_in_builds" do
    it "properly filters out pull requests where the `current_sha` exists in a build" do
      filtered_pull_requests = service.send(:filter_pull_requests_with_commit_shas_in_builds)
      filtered_commit_shas = filtered_pull_requests.map(&:current_sha)

      # Expectations on filtered commit shas.
      expect(filtered_commit_shas).to include(master_unrun_sha, patch_1_unrun_sha_one, patch_1_unrun_sha_two)
      expect(filtered_commit_shas).not_to include(master_prev_run_sha_one, patch_2_prev_run_sha_one, patch_2_prev_run_sha_two)
    end
  end

  describe "#enqueue_new_builds" do
    before(:each) do
      number_of_builds = pull_request_doubles.size
      service.should_receive(:create_and_queue_build_task).exactly(number_of_builds).times
    end

    it "enqueues all the new builds properly" do
      service.send(:enqueue_new_builds, pull_request_doubles)
    end
  end
end
