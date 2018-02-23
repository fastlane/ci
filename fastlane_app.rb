# External
require "sinatra/base"

set :server, "thin"

require_relative "./fastfile-parser/fastfile_parser"

# Internal
require_relative "services/services"
require_relative "workers/refresh_config_data_sources_worker"
require_relative "shared/logging_module"
require_relative "shared/fastlane_ci_error" # TODO: move somewhere else
require_relative "features/test_runner/test_runner"

# All things fastlane ci related go in this module
module FastlaneCI
  # Used to use the same layout file across all views
  # https://stackoverflow.com/questions/26080599/sinatra-method-to-set-layout
  def self.default_layout
    "../../../features/global/layout".to_sym
  end

  # Our CI app main class
  class FastlaneApp < Sinatra::Base
    include FastlaneCI::Logging
    Thread.current[:thread_id] = "main"

    get "/" do
      if session[:user]
        redirect("/dashboard")
      else
        redirect("/login")
      end
    end

    get "/favico.ico" do
      "nope"
    end
  end
end
