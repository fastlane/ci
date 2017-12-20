require_relative "config_data_sources/git_config_data_source"

module FastlaneCI
  class ConfigService
    attr_accessor :config_data_source

    def initialize(config_data_source: FastlaneCI::FastlaneApp::CONFIG_DATA_SOURCE)
      self.config_data_source = config_data_source
    end

    def projects
      return self.config_data_source.projects.collect do |raw_project|
        Project.new(
          repo_url: raw_project["repo_url"],
          enabled: raw_project["enabled"]
        )
      end
    end

    def projects=(projects)
      self.config_data_source.projects = projects.collect do |project|
        {
          repo_url: project.repo_url,
          enabled: project.enabled
        }
      end
    end
  end
end
