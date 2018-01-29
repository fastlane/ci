require_relative "data_sources/build_data_source"

module FastlaneCI
  # Provides service-level access to build information
  class BuildService
    attr_accessor :data_source

    def initialize(data_source: BuildDataSource.new)
      self.data_source = data_source
    end

    def list_builds(project: nil)
      self.data_source.list_builds(project: project)
    end

    def add_build!(project: nil, build: nil)
      self.data_source.add_build!(project: project, build: build)

      # TODO: commit changes here
    end
  end
end
