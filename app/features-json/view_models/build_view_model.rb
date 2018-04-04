require_relative "../../shared/models/build"
require_relative "./view_model"

module FastlaneCI
  # View model to expose the details about a build.
  class BuildViewModel
    include ViewModel
    base_model(Build)

    def self.included_attributes
      return [:@number, :@status]
    end
  end
end
