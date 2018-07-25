require "spec_helper"
require "app/features/build_runner/remote_runner"

describe FastlaneCI::RemoteRunner do
  let(:service) { FastlaneCI::Agent::Service.new }
  # using port 9999 here in case you run tests and have an agent aleady running on the default port
  let(:grpc_client) { FastlaneCI::Agent::Client.new("localhost", 9999) }

  let(:remote_runner) do
    github_service = double("GithubService")
    git_fork_config = double("GitForkConfig")
    project = double("Project", id: "abc-123", project_name: "test name", lane: "test", platform: "ios", artifact_provider: "provider")
    trigger = double("Trigger", type: FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual])

    described_class.new(
      project: project,
      git_fork_config: git_fork_config,
      trigger: trigger,
      github_service: github_service,
      grpc: grpc_client
    )
  end

  before do
    allow(FastlaneCI::Services.build_service).to receive(:list_builds).and_return([])
    allow(FastlaneCI::Services.build_service).to receive(:add_build!)

    allow(remote_runner).to receive(:environment_variables_for_worker).and_return({})

    # stub out the persistence
    allow(remote_runner).to receive(:save_build_status!)
    allow(remote_runner).to receive(:save_build_status_locally!)
    allow(remote_runner).to receive(:persist_history!)
  end

  describe "#start" do
    it "makes a GRPC request to the service" do
      expect(grpc_client).to receive(:request_run_fastlane).and_return([])
      remote_runner.start
    end

    it "catches an exception if the server is not running" do
      error = FastlaneCI::Proto::InvocationResponse::Error.new(description: "The Agent is not available")
      expect(remote_runner).to receive(:handle_error).with(error)
      remote_runner.start
    end
  end

  describe "completions" do
    before do
      # stub out the grpc request, so we immediatly go set `completed`
      allow(grpc_client).to receive(:request_run_fastlane).and_return([])
    end

    it "sets completed when #start returns" do
      remote_runner.start
      expect(remote_runner).to be_completed
    end

    it "calls completion blocks" do
      message_box = []
      remote_runner.on_complete do
        message_box << "complete"
      end

      remote_runner.start
      expect(message_box).to eq(["complete"])
    end

    it "subscribe returns with no subscriber if the runner is complete" do
      message_box = []
      remote_runner.start

      expect(remote_runner).to be_completed
      subscriber = remote_runner.subscribe do
        # no-op
      end

      expect(subscriber).to eq(nil)
    end

    it "persists the history of events" do
      allow(grpc_client).to receive(:request_run_fastlane).and_return([FastlaneCI::Proto::InvocationResponse.new(state: :RUNNING)])

      expect(remote_runner).to receive(:persist_history!).and_call_original
      remote_runner.start
      artifact = remote_runner.current_build.artifacts.last
      expect(artifact.type).to eq("log")
      expect(File.read(artifact.reference)).to eq(%({"state":"RUNNING"}\n))
    end
  end

  describe "message callbacks" do
    let(:message_box) { [] }

    before do
      remote_runner.subscribe do |topic, payload|
        message_box << payload
      end
    end

    it "subscribe to events" do
      remote_runner.publish_to_all({ hello: "world" })
      expect(message_box.first).to eq({ hello: "world" })
    end

    it "replays history on subscribe" do
      remote_runner.publish_to_all(1)
      expect(message_box).to eq([1])

      message_box2 = []
      remote_runner.subscribe do |topic, payload|
        message_box2 << payload
      end

      # even though we subscribed after the first message was sent,
      # we still have it in message_box2
      expect(message_box2).to eq([1])

      # send a second message
      remote_runner.publish_to_all(2)

      # all message boxes have all messages
      expect(message_box).to eq([1, 2])
      expect(message_box2).to eq([1, 2])
    end

    it "unsubscribe from events" do
      subscriber = remote_runner.subscribe do |topic, payload|
        raise "this happened"
      end

      expect do
        remote_runner.publish_to_all(nil)
      end.to raise_error(RuntimeError)

      remote_runner.unsubscribe(subscriber)

      expect do
        remote_runner.publish_to_all(nil)
      end.to_not(raise_error)
    end
  end

  it "topic name is scoped to the project id and build number" do
    expect(remote_runner.topic_name).to eq("remote_runner.abc-123.1")
  end

  describe "dispatches to message handlers" do
    let(:websocket_client) { double("WebsocketClient") }

    before do
      @subscriber = remote_runner.subscribe do |topic, payload|
        websocket_client.send(topic, payload)
      end
    end

    after do
      remote_runner.unsubscribe(@subscriber)
    end

    it "handles log events" do
      log = FastlaneCI::Proto::Log.new(message: "hello, world")
      allow(grpc_client).to receive(:request_run_fastlane).and_return([
                                                                        FastlaneCI::Proto::InvocationResponse.new(log: log)
                                                                      ])
      expect(remote_runner).to receive(:handle_log).with(log).and_call_original
      expect(websocket_client).to receive(:send).with("remote_runner.abc-123.1", {
        log: {
          message: "hello, world",
          level: :DEBUG,
          status: 0,
          timestamp: 0
        }
      })

      remote_runner.start
    end

    it "handles state events" do
      allow(grpc_client).to receive(:request_run_fastlane).and_return([
                                                                        FastlaneCI::Proto::InvocationResponse.new(state: :RUNNING)
                                                                      ])

      expect(remote_runner).to receive(:handle_state).and_call_original
      expect(remote_runner).to receive(:save_build_status!)
      expect(websocket_client).to receive(:send).with("remote_runner.abc-123.1", { state: :RUNNING })

      remote_runner.start
    end

    it "handles error events" do
      error = FastlaneCI::Proto::InvocationResponse::Error.new(description: "An error occured")
      allow(grpc_client).to receive(:request_run_fastlane).and_return([
                                                                        FastlaneCI::Proto::InvocationResponse.new(error: error)
                                                                      ])

      expect(remote_runner).to receive(:handle_error).with(error).and_call_original
      expect(websocket_client).to receive(:send).with("remote_runner.abc-123.1", {
        error: {
          description: "An error occured",
          file: "",
          line_number: 0,
          stacktrace: "",
          exit_status: 0
        }
      })

      remote_runner.start
    end

    it "handles artifact events" do
      artifact = FastlaneCI::Proto::InvocationResponse::Artifact.new(chunk: "abc123", filename: "test.txt")
      allow(grpc_client).to receive(:request_run_fastlane).and_return([
                                                                        FastlaneCI::Proto::InvocationResponse.new(artifact: artifact)
                                                                      ])
      expect(remote_runner).to receive(:handle_artifact).with(artifact).and_call_original
      # do not publish artifacts
      expect(websocket_client).to_not(receive(:send))

      remote_runner.start

      artifact = remote_runner.current_build.artifacts.last
      expect(File.read(artifact.reference)).to eq("abc123")
    end
  end
end
