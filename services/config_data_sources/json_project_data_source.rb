require_relative "project_data_source"
require_relative "../data_sources/json_data_source"
require_relative "../../shared/json_convertible"
require_relative "../../shared/models/git_repo"
require_relative "../../shared/models/git_repo_config"
require_relative "../../shared/models/project"
require_relative "../../shared/models/provider_credential"
require_relative "../../shared/logging_module"

module FastlaneCI
  # Mixin for Project to enable some basic JSON marshalling and unmarshalling
  class Project
    include FastlaneCI::JSONConvertible

    def self.attribute_to_type_map
      return { :@repo_config => GitRepoConfig }
    end
  end

  # Mixin for GitRepoConfig to enable some basic JSON marshalling and unmarshalling
  class GitRepoConfig
    include FastlaneCI::JSONConvertible
  end

  # (default) Store configuration in git
  class JSONProjectDataSource < ProjectDataSource
    include FastlaneCI::JSONDataSource
    include FastlaneCI::Logging

    class << self
      attr_accessor :projects_file_semaphore
      attr_accessor :repos_file_semaphore
    end

    JSONProjectDataSource.projects_file_semaphore = Mutex.new
    JSONProjectDataSource.repos_file_semaphore = Mutex.new

    # Reference to FastlaneCI::GitRepo
    attr_accessor :git_repo

    # You can provide either a `user` or `provider_credential`
    # TODO: should it be just `provider_credential`?
    def initialize(git_repo_config: nil, user: nil, provider_credential: nil)
      raise "No git_repo_config provided" if git_repo_config.nil?

      logger.debug("Using #{git_repo_config.local_repo_path} for project storage")

      provider_credential ||= user.provider_credential(type: ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])

      @git_repo = FastlaneCI::GitRepo.new(git_config: git_repo_config, provider_credential: provider_credential)
    end

    def refresh_repo
      self.git_repo.pull
    end

    # Access configuration
    def projects
      JSONProjectDataSource.projects_file_semaphore.synchronize do
        path = self.git_repo.file_path("projects.json")
        return [] unless File.exist?(path)

        saved_projects = JSON.parse(File.read(path)).map(&Project.method(:from_json!))
        return saved_projects
      end
    end

    def projects=(projects)
      JSONProjectDataSource.projects_file_semaphore.synchronize do
        File.write(self.git_repo.file_path("projects.json"), JSON.pretty_generate(projects.map(&:to_object_dictionary)))
        self.git_repo.commit_changes!
      end
    end

    def git_repos
      JSONProjectDataSource.repos_file_semaphore.synchronize do
        path = self.git_repo.file_path("repos.json")
        return [] unless File.exist?(path)

        saved_git_repos = JSON.parse(File.read(path)).map { |repo_config_hash| GitRepoConfig.from_json!(repo_config_hash) }
        return saved_git_repos
      end
    end

    def save_git_repo_configs!(git_repo_configs: nil)
      JSONProjectDataSource.repos_file_semaphore.synchronize do
        path = self.git_repo.file_path("repos.json")
        File.write(path, JSON.pretty_generate(git_repo_configs.map(&:to_object_dictionary)))
      end
    end

    def create_project!(name: nil, repo_config: nil, enabled: nil, lane: nil)
      projects = self.projects
      new_project = Project.new(repo_config: repo_config,
                                enabled: enabled,
                                project_name: name,
                                lane: lane)
      projects.push(new_project)
      self.projects = projects
      return new_project
    end
  end
end
