require_relative "project_data_source"
require_relative "../data_sources/json_data_source"
require_relative "../../shared/json_convertible"
require_relative "../../shared/models/git_repo"
require_relative "../../shared/models/git_repo_config"
require_relative "../../shared/models/project"
require_relative "../../shared/models/user"
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

    def after_creation(**params)
      if params.nil?
        raise "Either user or a provider credential is mandatory."
      else
        if !params[:user] && !params[:provider_credential]
          raise "Either user or a provider credential is mandatory."
        else
          params[:provider_credential] ||= params[:user].provider_credential(type: ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])
          @git_repo = FastlaneCI::GitRepo.new(git_config: self.json_folder_path, provider_credential: params[:provider_credential])
        end
      end
    end

    def after_creation(params)
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

        saved_git_repos = JSON.parse(File.read(path)).map(&GitRepoConfig.method(:from_json!))
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
      projects = @projects
      new_project = Project.new(repo_config: repo_config,
                                enabled: enabled,
                                project_name: name,
                                lane: lane)
      if self.project_exist?(new_project.project_name)
        projects.push(new_project)
        @projects = projects
        logger.debug("Added project #{new_project.project_name} to projets.json in #{self.json_folder_path}")
        return new_project
      else
        logger.debug("Couldn't add project #{new_project.project_name} because it already exists")
        return nil
      end
    end

    # Define that the name of the project must be unique
    def project_exist?(name: nil)
      project = self.projects.select { |existing_project| existing_project.project_name.casecmp(name.downcase).zero? }.first
      return !project.nil?
    end

    def update_project!(project: nil)
      unless project.nil?
        raise "project must be configured with an instance of #{Project.name}" unless project.class <= Project
      end
      project_index = nil
      existing_project = nil
      @projects.each.with_index do |old_project, index|
        if old_project.project_name.casecmp(project.project_name.downcase).zero?
          project_index = index
          existing_project = old_project
          break
        end
      end

      if existing_project.nil?
        logger.debug("Couldn't update project #{project.project_name} because it doesn't exists")
        raise "Couldn't update project #{project.project_name} because it doesn't exists"
      else
        logger.debug("Updating project #{existing_project.project_name}, writing out to projects.json to #{json_folder_path}")
        @projects[project_index] = project
      end
    end
  end
end
