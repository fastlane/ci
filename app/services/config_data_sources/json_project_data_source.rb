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
require_relative "../json_deserializers/json_trigger_deserializer"

module FastlaneCI
  # Mixin for JobTrigger which is in an Array on Project
  class JobTrigger
    include FastlaneCI::JSONConvertible
  end

  # Mixin for Project to enable some basic JSON marshalling and unmarshalling
  class Project
    include FastlaneCI::JSONConvertible

    def self.attribute_to_type_map
      return { :@repo_config => GitHubRepoConfig }
    end

    def self.map_enumerable_type(enumerable_property_name: nil, current_json_object: nil)
      if enumerable_property_name == :@job_triggers
        return JSONTriggerDeserializer.new.deserialize!(
          type: current_json_object["type"],
          object: current_json_object
        )
      end
    end

    def self.json_to_attribute_name_proc_map
      provider_object_to_provider = proc { |object|
        provider_class = Object.const_get(object["class_name"])
        if provider_class.include?(JSONConvertible)
          provider = provider_class.from_json!(object)
          provider
        end
      }
      return { :@artifact_provider => provider_object_to_provider }
    end

    def self.attribute_name_to_json_proc_map
      provider_to_provider_object = proc { |provider|
        if provider.class.include?(JSONConvertible)
          hash = provider.to_object_dictionary
          hash
        end
      }
      return { :@artifact_provider => provider_to_provider_object }
    end
  end

  # Mixin for GitHubRepoConfig to enable some basic JSON marshalling and unmarshalling
  class GitHubRepoConfig
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

          environment_variable_data_source = project_specific_environment_variables_data_source(project: project)
          project.environment_variables = environment_variable_data_source.environment_variables

          project
        end

        return saved_projects
      end
    end

    def job_triggers_from_hash_array(job_trigger_array: nil)
      deserializer = JSONTriggerDeserializer.new

      return job_trigger_array.map do |job_trigger_hash|
        deserializer.deserialize!(
          type: job_trigger_hash["type"],
          object: job_trigger_hash
        )
      end
    end

    def projects=(projects)
      JSONProjectDataSource.projects_file_semaphore.synchronize do
        # First store the project specific configuration files, for every project
        projects.each do |project|
          environment_variable_data_source = project_specific_environment_variables_data_source(project: project)
          environment_variable_data_source.environment_variables = project.environment_variables
        end

        # now store things into the actual projects.json
        # We have to ignore the `environment_variables` instance variable, as it's stored in a separate file
        json_data = JSON.pretty_generate(projects.map do |project|
          project.to_object_dictionary(ignore_instance_variables: [:@environment_variables])
        end)
        File.write(git_repo.file_path("projects.json"), json_data)
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

      FileUtils.mkdir_p(File.join(json_folder_path, "projects", new_project.id))

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

    private

    def project_specific_environment_variables_data_source(project: nil)
      # Now access the project specific files here
      # that are in
      #
      #   `projects/[project_id]/[file].json
      #
      # more information on https://github.com/fastlane/ci/issues/643
      project_specific_path = File.join(git_repo.file_path("projects"), project.id)
      return JSONEnvironmentDataSource.create(project_specific_path)
    end
  end
end
