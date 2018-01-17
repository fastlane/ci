# External
require "sinatra/base"
require "tty-command"
require "json" # TODO: move somewhere else
require "securerandom"
# Internal
require_relative "services/fastlane_ci_error" # TODO: move somewhere else, both the file and the `require`
require_relative "services/data_sources/json_data_source"
require_relative "services/config_data_sources/git_config_data_source"
require_relative "services/code_hosting_sources/git_hub_source"
require_relative "services/config_data_sources/config_base" # TODO: we don't want to import this here
require_relative "features/dashboard/models/project" # TODO: we don't want to import this here
require_relative "workers/refresh_config_data_sources_worker"
require_relative "shared/logging_module"

module FastlaneCI
  include FastlaneCI::Logging

  # Used to use the same layout file across all views
  # https://stackoverflow.com/questions/26080599/sinatra-method-to-set-layout
  def self.default_layout
    "../../../features/global/layout".to_sym
  end

  class FastlaneApp < Sinatra::Base
    DATA_SOURCE = JSONDataSource.new
    CMD = TTY::Command.new # Fx: not 100% sure if we want to keep this global, but might be good to have shared config and go from there (e.g. dupe object if we need to run a one-off)
    CONFIG_DATA_SOURCE = GitConfigDataSource.new(git_url: "https://github.com/KrauseFx/ci-config")

    get "/" do
      if FastlaneCI::GitHubSource.source_from_session(session).session_valid?
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
