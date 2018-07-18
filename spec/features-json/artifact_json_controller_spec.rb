require "spec_helper"
require "app/features-json/artifact_json_controller"

describe FastlaneCI::ArtifactJSONController do
  let(:app) { described_class.new }
  let(:json) { JSON.parse(last_response.body) }

  let(:build_number) { 1 }
  let(:artifact_id) { "123-123" }

  before do
    header("Authorization", bearer_token)

    project_service = "project_service"
    allow(FastlaneCI::Services).to receive(:project_service).and_return(project_service)
    project = "project"
    allow(project_service).to receive(:project_by_id).and_return(project)
    build = FastlaneCI::Build.new(
      project: nil,
      number: build_number,
      status: nil,
      timestamp: nil,
      duration: nil,
      description: nil,
      trigger: nil,
      lane: nil,
      platform: nil,
      parameters: nil,
      git_fork_config: nil,
      build_tools: nil
    )
    provider = "provider"
    allow(provider).to receive(:retrieve!).and_return("reference")
    artifact = FastlaneCI::Artifact.new(
      type: "ipa",
      reference: "reference",
      provider: provider,
      id: artifact_id
    )

    allow(build).to receive(:artifacts).and_return([artifact])
    allow(project).to receive(:builds).and_return([build])
  end

  describe "GET /data/project/:project_id/build/:build_number/artifact/:artifact_id" do
    it "returns the settings" do
      get("/data/project/project_id/build/#{build_number}/artifact/#{artifact_id}")
      expect(last_response).to be_ok
      expect(json).to eq({ "id" => "123-123", "type" => "ipa", "reference" => "reference", "provider" => "provider", "uri" => "reference" })
    end

    it "returns an error if artifact isn't available" do
      project_id = "project_id"

      get("/data/project/#{project_id}/build/#{build_number}/artifact/not_here")
      expect_json_error(
        message: "Couldn't find artifact",
        key: "Artifact.Missing",
        status: 404
      )
    end
  end
end
