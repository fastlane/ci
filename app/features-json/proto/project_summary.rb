module FastlaneCI::Proto
  # All metadata about a project.
  # A project is usually a git url, a lane, and a project name, like "Production Build"
  class Project
    # @return [String] Name of the project, also shows up in status as "fastlane.ci: #{project_name}"
    attr_accessor :project_name

    # @return [String] Is a UUID so we're not open to ID guessing attacks
    attr_accessor :id

    def initialize(project_name:, id:)
      self.project_name = project_name
      self.id = id
    end
  end
end
