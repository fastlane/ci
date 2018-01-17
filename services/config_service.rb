require_relative "config_data_sources/git_config_data_source"

module FastlaneCI
  class ConfigService
    attr_accessor :config_data_source

    def initialize(config_data_source: FastlaneCI::FastlaneApp::CONFIG_DATA_SOURCE)
      self.config_data_source = config_data_source
    end

    def projects(user_session)
      projects = self.config_data_source.projects.collect do |raw_project|
        Project.new(
          repo_url: raw_project["repo_url"],
          enabled: raw_project["enabled"],
          project_name: raw_project["project_name"],
          id: raw_project["id"]
        )
      end

      # Now we have to iterate over all added projects
      # and see if the current GitHub user has access to them
      access_to_repos = user_session.repos.collect { |r| r[:html_url] }
      projects.keep_if do |project|
        access_to_repos.include?(project.repo_url)
      end
      # Potentially we want to improve the above code, to still
      # indicate that there are projects there, but you just don't have
      # permission to access it

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
