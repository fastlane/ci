require_relative "project_data_source"
require_relative "../data_sources/json_data_source"
require_relative "../../shared/json_convertible"
require_relative "../../shared/models/git_repo"
require_relative "../../shared/models/git_hub_repo_config"
require_relative "../../shared/models/job_trigger"
require_relative "../../shared/models/project"
require_relative "../../shared/models/user"
require_relative "../../shared/models/provider_credential"
require_relative "../../shared/logging_module"

module FastlaneCI
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
          params[:provider_credential] ||= params[:user].provider_credential(
            type: ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
          )
          git_config = params[:git_config]

          @git_repo = FastlaneCI::GitRepo.new(
            git_config: git_config,
            local_folder: json_folder_path,
            provider_credential: params[:provider_credential],
            notification_service: params[:notification_service]
          )
        end
      end
    end

    def refresh_repo
      logger.debug("Pulling `master` in refresh_repo")
      git_repo.pull
    end

    # Access configuration
    def projects
      JSONProjectDataSource.projects_file_semaphore.synchronize do
        path = git_repo.file_path("projects.json")
        return [] unless File.exist?(path)

        saved_projects = JSON.parse(File.read(path)).map do |project_json|
          project = Project.from_json!(project_json)
          project
        end

        return saved_projects
      end
    end

    def job_triggers_from_hash_array(job_trigger_array: nil)
      return job_trigger_array.map do |job_trigger_hash|
        type = job_trigger_hash["type"]

        # currently only supports 3 triggers
        job_trigger = nil
        if type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit]
          job_trigger = CommitJobTrigger.from_json!(job_trigger_hash)
        elsif type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:nightly]
          job_trigger = NightlyJobTrigger.from_json!(job_trigger_hash)
        elsif type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual]
          job_trigger = ManualJobTrigger.from_json!(job_trigger_hash)
        else
          raise "Unable to parse JobTrigger type: #{type} from #{job_trigger_hash}"
        end
        job_trigger
      end
    end

    def projects=(projects)
      JSONProjectDataSource.projects_file_semaphore.synchronize do
        File.write(git_repo.file_path("projects.json"), JSON.pretty_generate(projects.map(&:to_object_dictionary)))
      end
    end

    def git_repos
      JSONProjectDataSource.repos_file_semaphore.synchronize do
        path = git_repo.file_path("repos.json")
        return [] unless File.exist?(path)

        saved_git_repos = JSON.parse(File.read(path)).map(&RepoConfig.method(:from_json!))
        return saved_git_repos
      end
    end

    def save_git_repo_configs!(git_repo_configs: nil)
      JSONProjectDataSource.repos_file_semaphore.synchronize do
        path = git_repo.file_path("repos.json")
        File.write(path, JSON.pretty_generate(git_repo_configs.map(&:to_object_dictionary)))
      end
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
      projects_clone = projects.clone
      new_project = Project.new(
        repo_config: repo_config,
        enabled: enabled,
        project_name: name,
        platform: platform,
        lane: lane,
        artifact_provider: artifact_provider,
        job_triggers: job_triggers
      )
      if !project_exist?(new_project.project_name)
        projects_clone << new_project
        self.projects = projects_clone
        logger.debug("Added project #{new_project.project_name} to projects.json in #{json_folder_path}")
        return new_project
      else
        logger.debug("Couldn't add project #{new_project.project_name} because it already exists")
        return nil
      end
    end

    # Define that the name of the project must be unique
    def project_exist?(name)
      return projects.any? { |existing_project| existing_project.project_name == name }
    end

    def update_project!(project: nil)
      unless project.nil?
        raise "project must be configured with an instance of #{Project.name}" unless project.class <= Project
      end
      project_index = nil
      existing_project = nil
      projects.each.with_index do |old_project, index|
        if old_project.id.casecmp(project.id.downcase).zero?
          project_index = index
          existing_project = old_project
          break
        end
      end

      if existing_project.nil?
        logger.debug("Couldn't update project #{project.project_name} because it doesn't exists")
        raise "Couldn't update project #{project.project_name} because it doesn't exists"
      else
        project_name = existing_project.project_name
        logger.debug("Updating project #{project_name}, writing out to projects.json to #{json_folder_path}")

        projects = self.projects
        projects[project_index] = project
        self.projects = projects
      end
    end

    def delete_project!(project: nil)
      unless project.nil?
        raise "project must be configured with an instance of #{Project.name}" unless project.class <= Project
      end
      project_index = nil
      existing_project = nil
      projects.each.with_index do |old_project, index|
        if old_project.id.casecmp(project.id.downcase).zero?
          project_index = index
          existing_project = old_project
          break
        end
      end

      if existing_project.nil?
        logger.debug("Couldn't delete project #{project.project_name} because it doesn't exists")
        raise "Couldn't update project #{project.project_name} because it doesn't exists"
      else
        project_name = existing_project.project_name
        logger.debug("Deleting project #{project_name}, writing out to projects.json to #{json_folder_path}")

        projects = self.projects
        projects.delete_at(project_index)
        self.projects = projects
      end
    end
  end
end
