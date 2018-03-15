require_relative "config_data_sources/json_project_data_source"
require_relative "../shared/models/repo_config"
require_relative "../shared/models/local_artifact_provider"
require_relative "../shared/models/gcp_artifact_provider"
require_relative "../shared/models/git_repo"
require_relative "../shared/logging_module"
require_relative "./user_service"
require_relative "./services"

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

    def create_project!(name: nil, repo_config: nil, enabled: nil, platform: nil, lane: nil, job_triggers: [], artifact_provider: nil)
      unless repo_config.nil?
        raise "repo_config must be configured with an instance of #{RepoConfig.name}" unless repo_config.class <= RepoConfig
      end
      if lane.nil?
        raise "lane parameter must be configured"
      end
      # we can guess the other parameters if not provided
      # the name parameter can be inferred from the url of the repo. (i.e., "https://gitub.com/fastlane/ci" -> "fastlane/ci")
      name ||= repo_config.git_url.split("/").last(2).join("/")
      # we infer that the new project will be enabled by default
      enabled ||= true
      # we use LocalArtifactProvider by default
      artifact_provider ||= LocalArtifactProvider.new
      project = self.project_data_source.create_project!(
        name: name,
        repo_config: repo_config,
        enabled: enabled,
        platform: platform,
        lane: lane,
        job_triggers: job_triggers,
        artifact_provider: artifact_provider
      )
      raise "Project couldn't be created" if project.nil?
      return project
    end

    def update_project!(project: nil)
      self.project_data_source.update_project!(project: project)
    end

    # @return [Project]
    def project(name: nil)
      if self.project_data_source.project_exist?(name)
        return self.project_data_source
                   .projects
                   .select { |existing_project| existing_project.project_name == name }
                   .first
      end
    end

    # @return [Project]
    def project_by_id(id)
      return self.project_data_source.projects.select { |project| project.id == id }.first
    end

    # TODO: remove this, we shouldn't be exposing implicitly private variables here
    # @return [GitRepo]
    def git_repo
      return self.project_data_source.git_repo
    end

    def refresh_repo
      self.git_repo.pull
    end

    # @return [Array[Project]]
    def projects
      return self.project_data_source.projects
    end

    def delete_project!(project: nil)
      self.project_data_source.delete_project!(project: project)
    end
  end
end
