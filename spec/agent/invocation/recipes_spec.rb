require "spec_helper"
require "agent/invocation/recipes"

describe FastlaneCI::Agent::Recipes do
  let(:queue) { Queue.new }
  class RecipesIncludingClass
    include FastlaneCI::Agent::Recipes
  end
  subject { RecipesIncludingClass.new }

  before do
    subject.output_queue = queue
  end

  it "shell commands put the command, and stdout and stderr on the output queue" do
    subject.sh("echo foo")
    expect(queue.pop).to eq("echo foo")
    expect(queue.pop).to eq("foo\n")

    subject.sh("echo error 1>&2")
    expect(queue.pop).to eq("echo error 1>&2")
    expect(queue.pop).to eq("error\n")
  end

  it "makes sure the bundler env is clean when shelling out" do
    ENV["BUNDLER_GEMFILE"] = "/foo/bar/Gemfile"
    subject.sh("env")

    expect(queue.pop).to_not(include("BUNDLER_GEMFILE")) until queue.empty?
  end

  it "raises an exception if a command exits non-zero" do
    expect do
      subject.sh("false")
    end.to raise_error(SystemCallError)
  end

  it "runs a command with the environment" do
    command = FastlaneCI::Proto::Command.new(bin: "env", env: { "FASTLANE_CI_ARTIFACTS" => "/tmp/ci/artifacts" })
    subject.run_fastlane(command)
    rows = []
    rows << queue.pop until queue.empty?

    expect(rows).to include("FASTLANE_CI_ARTIFACTS=/tmp/ci/artifacts\n")
  end
end
