require "spec_helper"
require "app/features-json/build_json_controller"

describe FastlaneCI::BuildJSONController do
  let(:app) { described_class.new }
  let(:json) { JSON.parse(last_response.body) }
  let(:git_fork_config) { double("GitForkConfig", clone_url: "https://github.com/fastlane/ci", branch: "master", ref: "abc", sha: "def") }

  let(:project) do
    FastlaneCI::Project.new(id: "abc-123")
  end

  let(:build) do
    FastlaneCI::Build.new(number: 1, project: project, git_fork_config: git_fork_config)
  end

  let(:user) { double("User", provider_credential: "github") }

  let(:project_service) do
    double("ProjectService", project_by_id: project)
  end

  before do
    stub_git_repos
    stub_services

    header("Authorization", bearer_token)
    allow(FastlaneCI::Services).to receive(:project_service).and_return(project_service)
    allow(FastlaneCI::Services.user_service).to receive(:find_user).and_return(user)
    allow(project).to receive(:builds).and_return([build])
  end

  describe "GET /data/projects/:project_id/build/:build_number" do
    it "responses with JSON of the build" do
      get("/data/projects/#{project.id}/build/#{build.number}")
      expect(last_response).to be_ok
      expect(json.keys).to include("artifacts", "branch", "build_tools", "clone_url", "description", "duration", "lane", "number", "parameters", "platform", "project_id", "ref", "sha", "status", "trigger")
    end
  end

  describe "POST /data/projects/:project_id/build/:build_number/rebuild" do
    # TODO(snatchev): complete this spec
    xit "enqueues a Runner and responds with JSON of the build" do
      expect(FastlaneCI::Services.build_runner_service).to receive(:add_build_runner).with(instance_of(FastlaneCI::RemoteRunner))

      post("/data/projects/#{project.id}/build/#{build.number}/rebuild")

      expect(last_response).to be_ok
    end
  end

  describe "GET /data/projects/:project_id/build/:build_number/logs" do
    # TODO(snatchev): complete this spec
    xit "responds with JSON containing logs of the Runner"
  end

  describe "GET /data/projects/:project_id/build/:build_number/logs.ws" do
    # TODO(snatchev): complete this spec
    xit "uses websocket to stream Runner events"
  end
end
