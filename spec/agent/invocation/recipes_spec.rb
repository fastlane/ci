require "spec_helper"
require "agent/invocation/recipes"

describe FastlaneCI::Agent::Recipes do
  let(:queue) { Queue.new }

  before do
    FastlaneCI::Agent::Recipes.output_queue = queue
  end

  it "shell commands put the command, and stdout and stderr on the output queue" do
    FastlaneCI::Agent::Recipes.sh("echo foo")
    expect(queue.pop).to eq("echo foo")
    expect(queue.pop).to eq("foo\n")

    FastlaneCI::Agent::Recipes.sh("echo error 1>&2")
    expect(queue.pop).to eq("echo error 1>&2")
    expect(queue.pop).to eq("error\n")
  end

  it "raises an exception if a command exits non-zero" do
    expect do
      FastlaneCI::Agent::Recipes.sh("false")
    end.to raise_error(SystemCallError)
  end
end
