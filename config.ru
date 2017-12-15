require "./fastlane_app"

# require all controllers
require_relative "features/dashboard/dashboard_controller"

# Load up all the available controllers
use FastlaneCI::DashboardController

# Start the CI app
run FastlaneCI::FastlaneApp
