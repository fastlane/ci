require_relative "./config_data_sources/json_project_data_source"
require_relative "./config_service"
require_relative "./worker_service"
require_relative "./user_service"
require_relative "./data_sources/json_user_data_source"
require_relative "./data_sources/json_build_data_source"
require_relative "./code_hosting/git_hub_service"

module FastlaneCI
  # A class that stores the singletones for each
  # service we provide
  class Services
    class << self
      attr_reader :ci_config_repo

      def ci_config_repo=(value)
        # When setting a new CI config repo
        # we gotta make sure to also re-init all the other
        # services and variables we use
        # TODO: Verify that we actually need to do this
        @_user_service = nil
        @_build_service = nil
        @_project_data_source = nil
        @_ci_user = nil
        @_config_service = nil
        @_worker_service = nil

        @ci_config_repo = value
      end
    end

    ########################################################
    # Service helpers
    ########################################################

    # Get the path to where we store fastlane.ci configuration
    def self.ci_config_git_repo_path
      self.ci_config_repo.local_repo_path
    end

    def self.ci_user
      # Find our fastlane.ci system user
      @_ci_user ||= Services.user_service.login(
        email: ENV["FASTLANE_CI_USER"],
        password: ENV["FASTLANE_CI_PASSWORD"],
        ci_config_repo: self.ci_config_repo
      )
    end

    # Start our project data source
    # TODO: this should be accessed through a ProjectDataService
    def self.project_data_source
      @_project_data_source ||= FastlaneCI::JSONProjectDataSource.new(
        git_repo_config: ci_config_repo,
        user: ci_user
      )
    end

    ########################################################
    # Services that we provide
    ########################################################

    # Start up a UserService from our JSONUserDataSource
    def self.user_service
      @_user_service ||= FastlaneCI::UserService.new(
        user_data_source: JSONUserDataSource.new(json_folder_path: ci_config_git_repo_path)
      )
    end

    # Start up the BuildService
    def self.build_service
      @_build_service ||= FastlaneCI::BuildService.new(
        build_data_source: JSONBuildDataSource.new(json_folder_path: ci_config_git_repo_path)
      )
    end

    # Grab a config service that is configured for the CI user
    def self.config_service
      @_config_service ||= FastlaneCI::ConfigService.new(ci_user: ci_user)
    end

    def self.worker_service
      @_worker_service ||= FastlaneCI::WorkerService.new
    end
  end
end
