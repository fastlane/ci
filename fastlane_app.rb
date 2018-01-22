# External
require "sinatra/base"
require "tty-command"
require "json" # TODO: move somewhere else
require "securerandom"

# Internal
require_relative "services/fastlane_ci_error" # TODO: move somewhere else, both the file and the `require`
require_relative "services/config_data_sources/git_config_data_source"
require_relative "services/code_hosting_sources/git_hub_source"
require_relative "features/dashboard/models/build" # TODO: we don't want to import this here
require_relative "workers/refresh_config_data_sources_worker"
require_relative "workers/check_for_new_commits_worker"
require_relative "shared/logging_module"

# All things fastlane ci related go in this module
module FastlaneCI
  include FastlaneCI::Logging

  # Used to use the same layout file across all views
  # https://stackoverflow.com/questions/26080599/sinatra-method-to-set-layout
  def self.default_layout
    "../../../features/global/layout".to_sym
  end

  # Our CI app main class
  class FastlaneApp < Sinatra::Base
    CONFIG_DATA_SOURCE = GitConfigDataSource.new(git_url: "https://github.com/KrauseFx/ci-config")

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

    # Initialize the workers
    # For now, we're not using a fancy framework that adds multiple heavy dependencies
    # including a database, etc.
    FastlaneCI::RefreshConfigDataSourcesWorker.new
  end
end
