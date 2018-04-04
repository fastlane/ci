require_relative "../../shared/models/build"
require_relative "./view_model"

module FastlaneCI
  # View model to expose the basic info about a build.
  class BuildSummaryViewModel
    include ViewModel
    base_model(Build)

    def self.included_attributes
      return [:@number, :@status]
    end
  end
end
