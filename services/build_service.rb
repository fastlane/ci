require_relative "data_sources/build_data_source"

module FastlaneCI
  # Provides service-level access to build information
  class BuildService
    attr_accessor :build_data_source

    def initialize(build_data_source: nil)
      unless build_data_source.nil?
        raise "build_data_source must be descendant of #{BuildDataSource.name}" unless build_data_source.class <= BuildDataSource
      end

      self.build_data_source = build_data_source
    end

    def list_builds(project: nil)
      self.build_data_source.list_builds(project: project)
    end

    def add_build!(project: nil, build: nil)
      self.build_data_source.add_build!(project: project, build: build)

      # TODO: commit changes here
    end
  end
end
