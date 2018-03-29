# External
require "sinatra/base"
require "fastfile_parser"

# Internal
require_relative "app/services/services"
require_relative "app/workers/refresh_config_data_sources_worker"
require_relative "app/shared/logging_module"
require_relative "app/shared/environment_variables"
require_relative "app/shared/fastlane_ci_error" # TODO: move somewhere else
require_relative "app/features/build_runner/build_runner"

# All things fastlane ci related go in this module
module FastlaneCI
  # Used to use the same layout file across all views
  # https://stackoverflow.com/questions/26080599/sinatra-method-to-set-layout
  def self.default_layout
    "../../../features/global/layout".to_sym
  end

  def self.env 
    @env ||= FastlaneCI::EnvironmentVariables.new
  end

  # Our CI app main class
  class FastlaneApp < Sinatra::Base 
    include FastlaneCI::Logging
    Thread.current[:thread_id] = "main"

    # Switch from the default Sinatra web server to `thin`
    # which is required to support web socket streams for the
    # display of real-time output
    set(:server, "thin")
    if ENV["WEB_APP"]
      # Anything except a data route
      get %r{/(?!data.*).*} do
        # Use Angular Web App instead
        send_file(File.join("public", ".dist", "index.html"))
      end
    else
      get "/" do
        if session[:user]
          redirect("/dashboard_erb")
        else
          redirect("/login_erb")
        end
      end

      get "/favico.ico" do
        "nope" # TODO: Add favicon once we have it
      end
    end
  end
end
