require_relative "../../shared/models/project"
require_relative "./view_model"

module FastlaneCI
  # View model to expose the details about a project.
  class ProjectViewModel
    include ViewModel
    base_model(Project)

    def self.included_attributes
      return [:@id, :@project_name]
    end
  end
end
