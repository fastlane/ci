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

    # @return [GitRepoConfig] URL to the Git repo
    attr_accessor :repo_config

    # @return [String] Name of the project, also shows up in status as "fastlane.ci: #{project_name}"
    attr_accessor :project_name

    # @return [String] lane name to run
    attr_accessor :lane

    # @return [Boolean]
    attr_accessor :enabled

    # @return [String] Is a UUID so we're not open to ID guessing attacks
    attr_accessor :id

    # @return [Array[JobTrigger]] The job triggers
    attr_accessor :job_triggers

    # @return [ArtifactProvider]
    attr_accessor :artifact_provider

    def initialize(repo_config: nil, enabled: nil, project_name: nil, lane: nil, id: nil, artifact_provider: LocalArtifactProvider.new)
      self.repo_config = repo_config
      self.enabled = enabled
      self.project_name = project_name
      self.id = id || SecureRandom.uuid
      self.lane = lane
      self.artifact_provider = artifact_provider
      # TODO: This is fine for now to avoid runtime fails due to lack of triggers.
      # In the future, the Add Project workflow, should provide the enough interface
      # in order to add as many JobTriggers as the user wants.
      self.job_triggers = [ManualJobTrigger.new(branch: "master")]
    end

    def builds
      builds = FastlaneCI::Services.build_service.list_builds(project: self)

      return builds.sort_by(&:number).reverse
    end

    def local_repo_path
      return File.join(File.expand_path("~/.fastlane/ci/"), self.id)
    end
  end
end
