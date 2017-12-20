# External
require "sinatra/base"
require "sinatra/reloader"
require "tty-command"
require "json" # TODO: move somewhere else

# Internal
require_relative "services/data_sources/json_data_source"
require_relative "services/config_data_sources/git_config_data_source"
require_relative "services/config_data_sources/config_base" # TODO: we don't want to import this here
require_relative "features/dashboard/models/project" # TODO: we don't want to import this here

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

    get "/" do
      redirect("/dashboard")
    end

    get "/favico.ico" do
      "nope"
    end
  end
end
