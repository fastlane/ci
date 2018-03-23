module FastlaneCI
  # Data source for all things related to builds
  class BuildDataSource
    # Array of all builds for the given project
    def list_builds(project: nil)
      not_implemented(__method__)
    end

    # Array of all builds for the given project that have the status `pending`
    def pending_builds(project: nil)
      not_implemented(__method__)
    end

    # Add or update a build
    def add_build!(project: nil, build: nil)
      not_implemented(__method__)
    end
  end
end
