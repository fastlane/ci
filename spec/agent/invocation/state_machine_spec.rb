require "spec_helper"
require "agent/invocation/state_machine"

describe FastlaneCI::Agent::StateMachine do
  # use a invocation class here to decouple from other side-effects
  class Invocation
    prepend FastlaneCI::Agent::StateMachine

    def send_state(_event, _payload)
      # no-op
    end

    def run
      "some return value"
    end
  end

  let(:invocation) { Invocation.new }
  let(:logger) { double("Logger", debug: nil, error: nil) }

  before do
    allow(invocation).to receive(:logger).and_return(logger)
  end

  it "creates a state machine with the expected states" do
    expect(invocation.states).to contain_exactly("pending", "running", "finishing", "succeeded", "rejected", "failed", "broken")
  end

  it "attempts to call `send_state` on a transition" do
    expect(invocation).to receive(:send_state).with(:run, nil)
    invocation.run
  end

  it "attempts to call an event callback if it's defined on the class only if the transition succeeded" do
    expect(invocation.run).to eq("some return value")
    expect(invocation.state).to eq("running")

    expect(invocation.run).to eq(nil)
  end
end
