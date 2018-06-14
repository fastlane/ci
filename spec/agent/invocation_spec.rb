require "spec_helper"
require "agent/invocation"
require "tempfile"

RSpec::Matchers.define(:proto_message) do |message|
  message = message.to_h unless message.kind_of?(Symbol)
  match do |actual|
    expect(actual.to_h).to include(message)
  end
end

describe FastlaneCI::Agent::Invocation do
  let(:yielder) { double("Yielder") }
  let(:invocation_request) { double("InvocationRequest") }
  let(:invocation) { described_class.new(invocation_request, yielder) }

  it "has states that are defined in the proto" do
    proto_states = FastlaneCI::Proto::InvocationResponse::State.constants
    proto_states.map! { |s| s.downcase.to_s }
    expect(invocation.states).to contain_exactly(*proto_states)
  end

  describe "#throw" do
    it "sends a state change and an exception back to the client" do
      expect(yielder).to receive(:<<).with(proto_message(state: :BROKEN))
      expect(yielder).to receive(:<<).with(proto_message(:error))
      begin
        raise "my dog hates technology"
      rescue StandardError => exception
        invocation.throw(exception)
      end
    end
  end

  describe "#reject" do
    before do
      allow(yielder).to receive(:<<).with(proto_message(state: :RUNNING))
      # can only transition to rejected after it's run
      invocation.state_machine.trigger(:run)
    end

    it "sends a state change and an exception back to the client" do
      expect(yielder).to receive(:<<).with(proto_message(state: :REJECTED))
      expect(yielder).to receive(:<<).with(proto_message(:error))
      invocation.reject(RuntimeError.new("my dog hates technology"))
    end
  end

  describe "#send_state" do
    it "sends the current state to the yielder triggered by a state change transition" do
      expect(yielder).to receive(:<<).with(proto_message(state: :PENDING))
      invocation.send_state("run", nil)
    end
  end

  describe "#send_log" do
    it "sends a log to the yielder" do
      expect(yielder).to receive(:<<).with(proto_message(log: { message: "this is a log line", level: :DEBUG, status: 0, timestamp: 1_234_567_890 }))
      Timecop.freeze(Time.utc(2009, 2, 13, 23, 31, 30)) do
        invocation.send_log("this is a log line")
      end
    end
  end

  describe "#send_file" do
    let(:file_path) { @file.path }

    before do
      @file = Tempfile.new("testfile")
      @file.sync = true
    end

    after do
      @file.close
      @file.unlink
    end

    it "send file chunks to the yielder until the file has been read" do
      @file.write("my cat loves technology\n") # 24 byte string.
      expect(yielder).to receive(:<<).with(proto_message(:artifact)).exactly(8).times # 24 / 3
      invocation.send_file(file_path, chunk_size: 3)
    end

    it "sends chunks an the filename" do
      @file.write("my cat loves technology\n") # 24 byte string.
      expected_filename = File.basename(file_path)
      expect(yielder).to receive(:<<).with(proto_message(artifact: { chunk: "my cat loves technology\n", filename: expected_filename }))
      invocation.send_file(file_path)
    end

    it "skips sending the file if the file does not exist" do
      expect(yielder).to_not(receive(:<<))
      expect(invocation.logger).to receive(:warn)
      invocation.send_file("/var/tmp/nonexistant_file")
    end
  end
end
