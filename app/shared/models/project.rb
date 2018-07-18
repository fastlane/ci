require "securerandom"

require_relative "../../shared/logging_module"
require_relative "artifact_provider"
require_relative "local_artifact_provider"
require_relative "job_trigger"

module FastlaneCI
  # All metadata about a project.
  # A project is usually a git url, a lane, and a project name, like "Production Build"
  class Project
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

    # @return [Array[EnvironmentVariable]] The project specific environment variables
    attr_accessor :environment_variables

    # @return [ArtifactProvider]
    attr_reader :artifact_provider

    def initialize(
      repo_config: nil,
      enabled: nil,
      project_name: nil,
      platform: nil,
      lane: nil,
      id: nil,
      environment_variables: nil,
      artifact_provider: LocalArtifactProvider.new,
      job_triggers: []
    )
      @repo_config = repo_config
      @enabled = enabled
      @project_name = project_name
      @id = id || SecureRandom.uuid
      @platform = platform
      @lane = lane
      @environment_variables = environment_variables || []
      @artifact_provider = artifact_provider
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
  end
end
