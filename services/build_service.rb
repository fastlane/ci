require_relative "data_sources/json_data_source"

module FastlaneCI
  # Provides service-level access to build information
  class BuildService
    BUILD_FILTERS = {
      all_builds: "all_builds",
      building: "building",
      completed: "completed"
    }.freeze

    attr_accessor :data_source

    def initialize(data_source: FastlaneCI::FastlaneApp::DATA_SOURCE)
      self.data_source = data_source
    end

    # query builds and return them along with a paging token if more builds exist
    def builds(filter: BUILD_FILTERS[:all_builds], maximum_builds_returned: 10)
      print("reminder: filter value: #{filter} is currently unused")
      data_source.load_builds(max: maximum_builds_returned) do |builds, paging_token|
        yield(builds, paging_token)
      end
    end
  end
end
