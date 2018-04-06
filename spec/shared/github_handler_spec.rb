require "spec_helper"
require "app/shared/github_handler"

describe FastlaneCI::GitHubHandler do
  class TestClass
    include FastlaneCI::GitHubHandler
  end

  it "adds handler methods on instances of a class" do
    test_class = TestClass.new
    expect(test_class).to respond_to(:github_action)
  end

  it "adds handler methods as static methods of a class" do
    expect(TestClass).to respond_to(:github_action)
  end
end
