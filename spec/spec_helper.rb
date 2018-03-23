require "bundler/setup"
$LOAD_PATH << File.dirname(File.expand_path("../", __FILE__))

require "rack/test"
require "rspec"
require "stub_helpers"
require "helper_functions"

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
end
