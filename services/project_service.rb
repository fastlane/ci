require_relative "config_data_sources/json_project_data_source"
require_relative "../shared/logging_module"

module FastlaneCI
  class ProjectService
    include FastlaneCI::Logging
    attr_accessor :project_data_source

    def initialize(project_data_source: nil)
      unless project_data_source.nil?
        raise "project_data_source must be descendant of #{ProjectDataSource.name}" unless project_data_source.class <= ProjectDataSource
      end

      if project_data_source.nil?
        # Default to JSONProjectDataSource
        logger.debug("project_data_source is new, using `ENV[\"data_store_folder\"]` if available, or `sample_data` folder")
        data_store_folder = ENV["data_store_folder"]
        data_store_folder ||= File.join(FastlaneCI::FastlaneApp.settings.root, "sample_data")
      end

    end
  end
end