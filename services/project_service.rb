require_relative "config_data_sources/json_project_data_source"
require_relative "../shared/../shared/models/repo_config"
require_relative "../shared/logging_module"

module FastlaneCI
  # Provides access to projects
  class ProjectService
    include FastlaneCI::Logging
    attr_accessor :project_data_source

    def initialize(project_data_source: nil)
      unless project_data_source.nil?
        raise "project_data_source must be descendant of #{ProjectDataSource.name}" unless project_data_source.class <= ProjectDataSource
      end

      self.project_data_source = project_data_source
    end

    def create_project!(name: nil, repo_config: nil, enabled: nil, lane: nil)
      unless repo_config.nil?
        raise "repo_config must be configured with an instance of #{RepoConfig.name}" unless repo_config.class <= RepoConfig
      end
      unless lane.nil?
        raise "lane parameter must be configured"
      end
      # we can guess the other parameters if not provided
      # the name parameter can be inferred from the url of the repo. (i.e., "https://gitub.com/fastlane/ci" -> "fastlane/ci")
      name ||= repo_config.git_url.split("/").last(2).join("/")
      # we infer that the new project will be enabled by default
      enabled ||= true
      project = self.project_data_source.create_project!(name: name, repo_config: repo_config, enabled: enabled, lane: lane)
      return project
    end
  end
end
