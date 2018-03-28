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

    def create_project!(name: nil, repo_config: nil, enabled: nil, platform: nil, lane: nil, artifact_provider: nil)
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
      project = self.project_data_source.create_project!(name: name, repo_config: repo_config, enabled: enabled, platform: platform, lane: lane, artifact_provider: artifact_provider)
      raise "Project couldn't be created" if project.nil?
      self.commit_repo_changes!(message: "Created project #{project.project_name}.")
      # We shallow clone the repo to have the information needed for retrieving lanes.
      return project
    end

    def update_project!(project: nil)
      self.project_data_source.update_project!(project: project)
      self.commit_repo_changes!(message: "Updated project #{project.project_name}.")
    end

    # @return [Project]
    def project(name: nil)
      if self.project_data_source.project_exist?(name)
        return self.project_data_source
                   .projects
                   .detect { |existing_project| existing_project.project_name == name }
      end
    end

    # @return [Project]
    def project_by_id(id)
      return self.project_data_source.projects.detect { |project| project.id == id }
    end

    # TODO: remove this, we shouldn't be exposing implicitly private variables here
    # @return [GitRepo]
    def git_repo
      return self.project_data_source.git_repo
    end

    def refresh_repo
      logger.debug("Pulling `master` in refresh_repo")
      self.git_repo.pull
    end

    # @return [Array[Project]]
    def projects
      return self.project_data_source.projects
    end

    # Ensure we have the projects checked out that we need
    # Returns all repos setup
    def update_project_repos(provider_credential: nil)
      configured_repos = []
      self.projects.each do |project|
        branches = project.job_triggers
                          .map(&:branch)
                          .uniq
        branches.each do |branch|
          logger.debug("Ensuring #{project.repo_config.git_url} (branch: #{branch}) is checked out")
          repo = GitRepo.new(
            git_config: project.repo_config,
            provider_credential: provider_credential,
            local_folder: File.join(project.local_repo_path, branch),
            async_start: false
          )
          configured_repos << repo
        end
      end
    end

    def delete_project!(project: nil)
      self.project_data_source.delete_project!(project: project)
      self.commit_repo_changes!(message: "Deleted project #{project.project_name}.")
    end

    # Not sure if this must be here or not, but we can open a discussion on this.
    def commit_repo_changes!(message: nil, file_to_commit: nil)
      Services.configuration_git_repo.commit_changes!(commit_message: message,
                                                        file_to_commit: file_to_commit)
    end

    def push_configuration_repo_changes!
      Services.configuration_git_repo.push
    end
  end
end
