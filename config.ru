require "./fastlane_app"

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
