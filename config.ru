require "rubygems"
require "bundler"

Bundler.require

# Don't even try to run without this
begin
  require "openssl"
rescue LoadError
  warn("Error: no such file to load -- openssl. Make sure you have openssl installed")
  exit(1)
end

if ENV["RACK_ENV"] == "development"
  Thread.abort_on_exception = true
end

if ENV["FASTLANE_CI_ENCRYPTION_KEY"].nil?
  warn("Error: unable to decrypt sensitive data without environment variable `FASTLANE_CI_ENCRYPTION_KEY` set")
  exit(1)
end

if ENV["FASTLANE_CI_USER"].nil? || ENV["FASTLANE_CI_PASSWORD"].nil?
  warn("Error: ensure you have your `FASTLANE_CI_USER` and `FASTLANE_CI_PASSWORD`environment variables set")
  exit(1)
end

if ENV["FASTLANE_CI_REPO_URL"].nil?
  warn("Error: ensure you have your `FASTLANE_CI_REPO_URL` environment variable set")
  exit(1)
end

# before running, call `bundle install --path vendor/bundle`
# this isolates the gems for bundler

require "./fastlane_app"

# allow use of `require` for all things under `shared`, helps with some cycle issues
$LOAD_PATH << "shared"

# require all controllers
require_relative "features/dashboard/dashboard_controller"
require_relative "features/login/login_controller"
require_relative "features/project/project_controller"

# Load up all the available controllers
use(FastlaneCI::DashboardController)
use(FastlaneCI::LoginController)
use(FastlaneCI::ProjectController)

# Start the CI app
run(FastlaneCI::FastlaneApp)
