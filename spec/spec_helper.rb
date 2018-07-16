require "bundler/setup"
$LOAD_PATH << File.dirname(File.expand_path("../", __FILE__))

require "coveralls"
Coveralls.wear!

require "rack/test"
require "rspec"
require "webmock/rspec"

require "stub_helpers"
require "api_helper"
require "helper_functions"
require "timecop"

ENV["RACK_ENV"] = "test"
require File.expand_path("../../fastlane_app.rb", __FILE__)

module RSpecMixin
  include Rack::Test::Methods

  def app
    FastlaneCI::FastlaneApp.new
  end
end

RSpec.configure do |config|
  config.include(RSpecMixin)
  config.include(StubHelpers)
  config.include(HelperFunctions)
  config.formatter = :documentation
  config.tty = true
  config.color = true

  config.before(:each) do
    stub_dot_keys
  end
end

# Do not allow reading on STDIN on tests. This will block the test run.
STDIN.close
