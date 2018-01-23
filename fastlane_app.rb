# External
require "sinatra/base"
require "tty-command"
require "json" # TODO: move somewhere else
require "securerandom"

# Internal
require_relative "services/config_data_sources/git_config_data_source"
require_relative "services/config_service"
require_relative "services/worker_service"
require_relative "services/user_service"
require_relative "services/data_sources/user_data_source"
require_relative "services/test_runner_service"
require_relative "services/fastlane_ci_error" # TODO: move somewhere else, both the file and the `require`

require_relative "services/code_hosting_sources/git_hub_source"
require_relative "features/dashboard/models/build" # TODO: we don't want to import this here
require_relative "workers/refresh_config_data_sources_worker"
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
    CONFIG_DATA_SOURCE = FastlaneCI::GitConfigDataSource.new(git_url: "https://github.com/KrauseFx/ci-config")
    json_folder_path = CONFIG_DATA_SOURCE.git_repo.path
    user_data_source = UserDataSource.new(json_folder_path: json_folder_path)
    USER_SERVICE = FastlaneCI::UserService.new(data_source: user_data_source)

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

    # Going ot start our workers
    @worker_service = FastlaneCI::WorkerService.new

    # Login the CI user
    @ci_user = USER_SERVICE.login(email: ENV["FASTLANE_CI_USER"], password: ENV["FASTLANE_CI_PASSWORD"])

    # Grab a config service that is configured for the CI user
    @ci_user_config_service = FastlaneCI::ConfigService.new(ci_user: @ci_user)

    # Iterate through all provider credentials and their projects and start a worker for each project
    @ci_user.provider_credentials.each do |provider_credential|
      projects = @ci_user_config_service.projects(provider_credential: provider_credential)
      projects.each do |project|
        @worker_service.start_worker_for_provider_credential_and_config(
          project: project,
          provider_credential: provider_credential
        )
      end
    end

    # Initialize the workers
    # For now, we're not using a fancy framework that adds multiple heavy dependencies
    # including a database, etc.
    FastlaneCI::RefreshConfigDataSourcesWorker.new
  end
end
