require_relative "config_data_sources/git_config_data_source"

module FastlaneCI
  class ConfigService
    attr_accessor :config_data_source

    def initialize(config_data_source: FastlaneCI::FastlaneApp::CONFIG_DATA_SOURCE)
      self.config_data_source = config_data_source
    end

    def projects(user_session)
      # Get a list of all the repos the user has access to
      access_to_repos = user_session.repos.collect { |r| r[:html_url] }

      projects = self.config_data_source.projects.collect do |raw_project|
        Project.new(
          repo_url: raw_project["repo_url"],
          enabled: raw_project["enabled"],
          project_name: raw_project["project_name"],
          current_user_has_access: access_to_repos.include?(raw_project["repo_url"]),
          id: raw_project["id"]
        )
      end

      return projects
    end

    def projects=(projects)
      self.config_data_source.projects = projects.collect do |project|
        {
          repo_url: project.repo_url,
          enabled: project.enabled,
          project_name: project.project_name,
          id: project.id
        }
      end
    end
  end
end
