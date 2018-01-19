require "rubygems"
require "bundler"

Bundler.require

# before running, call `bundle install --path vendor/bundle`
# this isolates the gems for bundler

require "./fastlane_app"

# allow use of `require` for all things under `shared`, helps with some cycle issues
$LOAD_PATH << 'shared'

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
