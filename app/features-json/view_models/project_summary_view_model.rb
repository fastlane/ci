require_relative "../../shared/models/project"
require_relative "../../shared/models/build"
require_relative "../../shared/json_convertible"

module FastlaneCI
  # View model to expose the basic info about a project.
  class ProjectSummaryViewModel
    include FastlaneCI::JSONConvertible

    # @return [String] Name of the project, also shows up in status as "fastlane.ci: #{project_name}"
    attr_accessor :name

    # @return [String] lane name to run
    attr_accessor :lane

    # @return [String] Is a UUID so we're not open to ID guessing attacks
    attr_reader :id

    # @return [String]
    attr_reader :repo_name

    # @return [String]
    attr_reader :latest_status

    # @return [DateTime] Start time
    attr_reader :latest_timestamp

    def initialize(project:, latest_build: nil)
      raise "Incorrect object type. Expected Project, got #{project.class}" unless project.kind_of?(Project)
      unless latest_build.nil?
        raise "Incorrect object type. Expected Build, got #{latest_build.class}" unless latest_build.kind_of?(Build)
      end

      @name = project.project_name
      @lane = project.lane
      @id = project.id
      @repo_name = project.repo_config.name
      @latest_status = latest_build&.status
      @latest_timestamp = latest_build&.timestamp
    end
  end
end
