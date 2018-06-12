require "spec_helper"
require "agent/service"

describe FastlaneCI::Agent::Service do
  let(:service) { FastlaneCI::Agent::Service.new }

  it "creates a new grpc service with .server" do
    expect(FastlaneCI::Agent::Service.server).to be_instance_of(GRPC::RpcServer)
  end

  describe "#spawn" do
    echo_message = "hello world"
    let(:command) { instance_double("FastlaneCI::Agent::Command", env: {}, bin: "/bin/echo", parameters: [echo_message]) }
    let(:call) { double("GRP Call") }

    it "spawns a command with the environment and parameters" do
      expect(Open3).to receive(:popen2e).and_call_original
      service.spawn(command, call)
    end

    it "returns a ProcessEnumerator that contains the output of the command" do
      responses = service.spawn(command, call)
      expect(responses).to be_instance_of(Enumerator::Lazy)
      expect(responses.peek.log.message).to start_with(echo_message)
      responses.each do |response|
        expect(response).to be_instance_of(FastlaneCI::Proto::InvocationResponse)
        expect(response.log).to be_instance_of(FastlaneCI::Proto::Log)
      end
    end
  end

  describe FastlaneCI::Agent::Service::ProcessOutputEnumerator do
    let(:io) { double("IO-like", gets: "this is a line of text\n") }

    let(:thread_value) { double("thread value") }
    let(:thread) { double("Thread", alive?: true, value: thread_value) }

    let(:output_enumerator) { FastlaneCI::Agent::Service::ProcessOutputEnumerator.new(io, thread) }

    it "will return lines of text from the file" do
      expect(output_enumerator.next).to eq("this is a line of text\n")
    end

    it "enumerates lines from a file until the thread dies and returns its status" do
      allow(thread).to receive(:alive?).and_return(false)
      allow(thread_value).to receive(:exitstatus).and_return(0)
      allow(io).to receive(:close)

      expect { |block| output_enumerator.each(&block) }.to yield_with_args("\4", 0)
    end

    it "closes the file handle when the thread dies" do
      allow(thread).to receive(:alive?).and_return(false)
      allow(thread_value).to receive(:exitstatus).and_return(0)

      expect(io).to receive(:close)
      output_enumerator.next
    end

    it "can convert to a lazy Enumerator" do
      expect(output_enumerator.lazy).to be_instance_of(Enumerator::Lazy)
    end
  end
end
