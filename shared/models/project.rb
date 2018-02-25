require "securerandom"

module FastlaneCI
  # All metadata about a project.
  # A project is usually a git url, a lane, and a project name, like "Production Build"
  class Project
    # @return [GitRepoConfig] URL to the Git repo
    attr_accessor :repo_config

    # @return [String] Name of the project
    attr_accessor :project_name

    # @return [String] lane name to run
    attr_accessor :lane

    # @return [Boolean]
    attr_accessor :enabled

    # @return [String] Is a UDID so we're not open to ID guessing attacks
    attr_accessor :id

    # @return [Array[JobTrigger]] The job triggers
    attr_accessor :job_triggers

    def initialize(repo_config: nil, enabled: nil, project_name: nil, lane: nil, id: nil)
      self.repo_config = repo_config
      self.enabled = enabled
      self.project_name = project_name
      self.id = id || SecureRandom.uuid
      self.lane = lane
    end

    def builds
      builds = FastlaneCI::Services.build_service.list_builds(project: self)

      return builds.sort_by(&:number).reverse
    end
  end
end
