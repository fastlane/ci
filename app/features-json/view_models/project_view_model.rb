require_relative "./build_summary_view_model"
require_relative "../../shared/models/project"
require_relative "../../shared/json_convertible"

module FastlaneCI
  # View model to expose the detailed info about a project.
  class ProjectViewModel
    include FastlaneCI::JSONConvertible

    # @return [String] Name of the project, also shows up in status as "fastlane.ci: #{project_name}"
    attr_accessor :name

    # @return [String] Is a UUID so we're not open to ID guessing attacks
    attr_reader :id

    # @return [String]
    attr_reader :repo_name

    # @return [String] lane name to run
    attr_accessor :lane

    # @return [Array[BuildSummaryViewModel]]
    attr_reader :builds

    def initialize(project:)
      raise "Incorrect object type. Expected Project, got #{project.class}" unless project.kind_of?(Project)

      @name = project.project_name
      @id = project.id
      @lane = project.lane
      @builds = project.builds.map { |build| BuildSummaryViewModel.new(build: build) }
      @repo_name = project.repo_config.name
    end
  end
end
