# External
require "sinatra/base"
require "sinatra/reloader"
require "tty-command"
require "json" # TODO: move somewhere else

# Internal
require_relative "services/fastlane_ci_error" # TODO: move somewhere else, both the file and the `require`
require_relative "services/data_sources/json_data_source"
require_relative "services/config_data_sources/git_config_data_source"
require_relative "services/code_hosting_sources/git_hub_source"
require_relative "services/config_data_sources/config_base" # TODO: we don't want to import this here
require_relative "features/dashboard/models/project" # TODO: we don't want to import this here
require_relative "workers/refresh_config_data_sources_worker"

module FastlaneCI
  class FastlaneApp < Sinatra::Base
    configure(:development) do |configuration|
      register Sinatra::Reloader
      configuration.also_reload "features/dashboard/dashboard_controller.rb"
      configuration.after_reload do
        puts "reloaded"
      end
    end

    DATA_SOURCE = JSONDataSource.new
    CMD = TTY::Command.new # Fx: not 100% sure if we want to keep this global, but might be good to have shared config and go from there (e.g. dupe object if we need to run a one-off)
    CONFIG_DATA_SOURCE = GitConfigDataSource.new(git_url: "https://github.com/KrauseFx/ci-config")

    # Set the default layout file across all controllers
    set :erb, :layout => ("../../../features/global/layout").to_sym

    get "/" do
      redirect("/login")
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
