require "securerandom"

require_relative "../../shared/logging_module"
require_relative "../json_convertible"
require_relative "artifact_provider"
require_relative "local_artifact_provider"
require_relative "job_trigger"

module FastlaneCI
  # All metadata about a project.
  # A project is usually a git url, a lane, and a project name, like "Production Build"
  class Project
    include FastlaneCI::JSONConvertible
    include FastlaneCI::Logging

    # @return [RepoConfig] Repo configuration
    attr_accessor :repo_config

    # @return [String] Name of the project, also shows up in status as "fastlane.ci: #{project_name}"
    attr_accessor :project_name

    # @return [String] platform name to run
    attr_accessor :platform

    # @return [String] lane name to run
    attr_accessor :lane

    # @return [Boolean]
    attr_accessor :enabled

    # @return [String] Is a UUID so we're not open to ID guessing attacks
    attr_reader :id

    # @return [Array[JobTrigger]] The job triggers
    attr_reader :job_triggers

    # @return [ArtifactProvider]
    attr_reader :artifact_provider

    def initialize(
      repo_config: nil,
      enabled: nil,
      project_name: nil,
      platform: nil,
      lane: nil,
      id: nil,
      artifact_provider: LocalArtifactProvider.new,
      job_triggers: []
    )
      @repo_config = repo_config
      @enabled = enabled
      @project_name = project_name
      @id = id || SecureRandom.uuid
      @platform = platform
      @lane = lane
      @artifact_provider = artifact_provider
      # TODO: This is fine for now to avoid runtime fails due to lack of triggers.
      # In the future, the Add Project workflow, should provide the enough interface
      # in order to add as many JobTriggers as the user wants.
      @job_triggers = job_triggers
    end

    def find_triggers_of_type(trigger_type:)
      return job_triggers.find_all do |current_trigger|
        current_trigger.type.to_sym == trigger_type.to_sym
      end
    end

    def builds
      builds = FastlaneCI::Services.build_service.list_builds(project: self)
      return builds.sort_by(&:number).reverse
    end

    def local_repo_path
      return File.join(File.expand_path("~/.fastlane/ci/"), id)
    end

    def self.attribute_to_type_map
      return { :@repo_config => GitHubRepoConfig }
    end

    def self.map_enumerable_type(enumerable_property_name: nil, current_json_object: nil)
      if enumerable_property_name == :@job_triggers
        type = current_json_object["type"]
        # currently only supports 3 triggers
        job_trigger = nil
        if type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit]
          job_trigger = CommitJobTrigger.from_json!(current_json_object)
        elsif type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:nightly]
          job_trigger = NightlyJobTrigger.from_json!(current_json_object)
        elsif type == FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual]
          job_trigger = ManualJobTrigger.from_json!(current_json_object)
        else
          raise "Unable to parse JobTrigger type: #{type} from #{current_json_object}"
        end
        job_trigger
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
end
