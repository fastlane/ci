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
    attr_reader :repo_config

    # @return [String] Name of the project, also shows up in status as "fastlane.ci: #{project_name}"
    attr_accessor :project_name

    # @return [String] platform name
    attr_accessor :platform

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

    def initialize(repo_config: nil, enabled: nil, project_name: nil, platform: nil, lane: nil, id: nil, job_triggers: [], artifact_provider: LocalArtifactProvider.new)
      self.repo_config = repo_config
      self.enabled = enabled
      self.project_name = project_name
      self.id = id || SecureRandom.uuid
      self.platform = platform
      self.lane = lane
      self.artifact_provider = artifact_provider
      self.job_triggers = job_triggers
    end

    def repo_config=(repo_config)
      unless repo_config.nil?
        repo_config.id = self.id
      end
      @repo_config = repo_config
    end

    def builds
      builds = FastlaneCI::Services.build_service.list_builds(project: self)

      return builds.sort_by(&:number).reverse
    end

    # if you're using this with the fastfile parser, you need to use `relative: false`
    def local_fastfile_path(relative: false, sha: nil)
      fastfile_path = nil

      # First assume the fastlane directory and its file is in the root of the project
      fastfiles = Dir[File.join(local_repo_path(sha: sha), "**/*", "fastlane/Fastfile")]
      # If not, it might be in a subfolder
      fastfiles = Dir[File.join(local_repo_path(sha: sha), "**/fastlane/Fastfile")] if fastfiles.count == 0

      if fastfiles.count > 1
        logger.error("Ugh, multiple Fastfiles found, we're gonna have to build a selection in the future")
        # for now, just take the first one
      end

      if fastfiles.count == 0
        logger.error("No Fastfile found at #{local_repo_path(sha: sha)}, or any descendants")
      else
        fastfile_path = fastfiles.first
        if relative
          fastfile_path = Pathname.new(fastfile_path).relative_path_from(Pathname.new(local_repo_path(sha: sha)))
        end
      end
      return fastfile_path
    end

    def local_repo_path(sha: nil)
      return File.join(File.expand_path("~/.fastlane/ci/"), self.id, self.repo_config.full_name, sha, self.repo_config.name)
    end
  end
end
