require "spec_helper"
require "agent/service"

describe FastlaneCI::Agent::Service do
  let(:service) { FastlaneCI::Agent::Service.new }

  it "creates a new grpc service with .server" do
    expect(FastlaneCI::Agent::Service.server).to be_instance_of(GRPC::RpcServer)
  end

  describe "#run_fastlane" do
    let(:call) { double("GRP Call") }
    let(:command) { instance_double("FastlaneCI::Agent::Command", env: {}, bin: "/bin/echo", parameters: ["hello world"]) }
    let(:request) { instance_double("FastlaneCI::Agent::InvocationRequest", command: command) }
    it "reject all requests while busy" do
      # stub StateMachine.run to keep the server busy for 3 sec when run_fastlane is called.
      allow_any_instance_of(FastlaneCI::Agent::StateMachine).to receive(:run) do
        raise RuntimeError("Exception in mocked StateMachine.run will generate 2 InvocationResponses")
      end

      # calling run_fastlane will not start the actual work until we start iterating on the response stream
      responses = service.run_fastlane(request, call)

      # reading the first InvocationResponse puts the agent into busy mode.
      responses.next

      2.times do
        busy_responses = service.run_fastlane(request, call)
        expect(busy_responses.next.state).to eq(:REJECTED)
        loop { busy_responses.next }
      end

      # Finish the task by reading the rest of the response stream;
      # This should put the agent back in non-busy mode.
      loop { responses.next }

      # Let's validate that once the running invocation is done we can accept new requests
      responses = service.run_fastlane(request, call)
      expect(responses.next.state).not_to(eq(:REJECTED))
      loop { responses.next }
    end
  end
end
