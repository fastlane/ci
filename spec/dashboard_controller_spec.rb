require "spec_helper"
require "app/features/dashboard/dashboard_controller.rb"

describe FastlaneCI::DashboardController do
  # This fails because Rack Test doesn't seem to be loading things from config.ru
  # it "should print out the test message" do
  #   get "/dashboard_erb"

  #   expect(last_response).to be_ok
  #   expect(last_response.body).to eq("Loading from ERB with 18 tacos")
  # end
end
