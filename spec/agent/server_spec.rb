require "spec_helper"
require "agent/server"

describe FastlaneCI::Agent::Server do
  let(:server) { FastlaneCI::Agent::Server.new }

  it "creates a new grpc server with .server" do
    expect(FastlaneCI::Agent::Server.server).to be_instance_of(GRPC::RpcServer)
  end

  describe "#spawn" do
    let(:command) { instance_double("FastlaneCI::Agent::Command", env: {}, bin: "/bin/echo", parameters: ["hello world"]) }
    let(:call) { double("GRP Call") }
    it "spawns a command with the environment and parameters" do
      expect(Open3).to receive(:popen2e).and_call_original
      server.spawn(command, call)
    end

    it "returns a ProcessEnumerator that contains the output of the command" do
      expect(server.spawn(command, call)).to be_instance_of(Enumerator::Lazy)
    end
  end

  describe FastlaneCI::Agent::Server::ProcessOutputEnumerator do
    let(:io) { double("IO-like", gets: "this is a line of text\n") }

    let(:thread_value) { double("thread value") }
    let(:thread) { double("Thread", alive?: true, value: thread_value) }

    let(:penum) { FastlaneCI::Agent::Server::ProcessOutputEnumerator.new(io, thread) }

    it "will return lines of text from the file" do
      expect(penum.next).to eq("this is a line of text\n")
    end

    it "enumerates lines from a file until the thread dies and returns its status" do
      allow(thread).to receive(:alive?).and_return(false)
      allow(thread_value).to receive(:exitstatus).and_return(0)
      allow(io).to receive(:close)

      expect { |block| penum.each(&block) }.to yield_with_args("\4", 0)
    end

    it "closes the file handle when the thread dies" do
      allow(thread).to receive(:alive?).and_return(false)
      allow(thread_value).to receive(:exitstatus).and_return(0)

      expect(io).to receive(:close)
      penum.next
    end

    it "can convert to a lazy Enumerator" do
      expect(penum.lazy).to be_instance_of(Enumerator::Lazy)
    end
  end
end
