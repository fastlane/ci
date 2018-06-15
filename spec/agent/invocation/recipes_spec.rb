require "spec_helper"
require "agent/invocation/recipes"

describe FastlaneCI::Agent::Recipes do
  let(:queue) { Queue.new }
  class RecipesIncludingClass
    include FastlaneCI::Agent::Recipes
  end
  before do
    @recipes_including_class = RecipesIncludingClass.new
    @recipes_including_class.output_queue = queue
  end

  it "shell commands put the command, and stdout and stderr on the output queue" do
    @recipes_including_class.sh("echo foo")
    expect(queue.pop).to eq("echo foo")
    expect(queue.pop).to eq("foo\n")

    @recipes_including_class.sh("echo error 1>&2")
    expect(queue.pop).to eq("echo error 1>&2")
    expect(queue.pop).to eq("error\n")
  end

  it "raises an exception if a command exits non-zero" do
    expect do
      @recipes_including_class.sh("false")
    end.to raise_error(SystemCallError)
  end
end
