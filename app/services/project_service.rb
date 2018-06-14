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
        unless project_data_source.class <= ProjectDataSource
          raise "project_data_source must be descendant of #{ProjectDataSource.name}"
        end
      end

      self.project_data_source = project_data_source
    end

    def create_project!(
      name: nil,
      repo_config: nil,
      enabled: nil,
      platform: nil,
      lane: nil,
      artifact_provider: nil,
      job_triggers: nil
    )
      unless repo_config.nil?
        unless repo_config.class <= RepoConfig
          raise "repo_config must be configured with an instance of #{RepoConfig.name}"
        end
      end
      if lane.nil?
        raise "lane parameter must be configured"
      end
      # we can guess the other parameters if not provided
      # the name parameter can be inferred from the url of the repo.
      # (i.e., "https://gitub.com/fastlane/ci" -> "fastlane/ci")
      name ||= repo_config.git_url.split("/").last(2).join("/")
      # we infer that the new project will be enabled by default
      enabled ||= true
      # we use LocalArtifactProvider by default
      artifact_provider ||= LocalArtifactProvider.new
      project = project_data_source.create_project!(
        name: name,
        repo_config: repo_config,
        enabled: enabled,
        platform: platform,
        lane: lane,
        artifact_provider: artifact_provider,
        job_triggers: job_triggers
      )
      raise "Project couldn't be created" if project.nil?
      commit_repo_changes!(message: "Created project #{project.project_name}.")
      # We shallow clone the repo to have the information needed for retrieving lanes.
      return project
    end

    def update_project!(project: nil)
      project_data_source.update_project!(project: project)
      commit_repo_changes!(message: "Updated project #{project.project_name}.")
    end

    # @return [Project]
    def project(name: nil)
      if project_data_source.project_exist?(name)
        return project_data_source.projects
                                  .detect { |existing_project| existing_project.project_name.casecmp(name).zero? }
      end
    end

    # @return [Project]
    def project_by_id(id)
      return project_data_source.projects.detect { |project| project.id == id }
    end

    # TODO: remove this, we shouldn't be exposing implicitly private variables here
    # @return [GitRepo]
    def git_repo
      return project_data_source.git_repo
    end

    def refresh_repo
      logger.debug("Pulling `master` in refresh_repo")
      git_repo.pull
    end

    # @return [Array[Project]]
    def projects
      return project_data_source.projects
    end

    def delete_project!(project: nil)
      project_data_source.delete_project!(project: project)
      commit_repo_changes!(message: "Deleted project #{project.project_name}.")
    end

    # Not sure if this must be here or not, but we can open a discussion on this.
    def commit_repo_changes!(message: nil, files_to_commit: [])
      Services.configuration_git_repo.commit_changes!(commit_message: message, files_to_commit: files_to_commit)
    end

    def push_configuration_repo_changes!
      Services.configuration_git_repo.push
    end
  end
end
