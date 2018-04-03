require_relative "data_sources/build_data_source"

module FastlaneCI
  # Provides service-level access to build information
  # This class is NOT responsible for running builds
  class BuildService
    attr_accessor :build_data_source

    def initialize(build_data_source: nil)
      if !build_data_source.nil? && build_data_source.class > BuildDataSource
        raise "build_data_source must be descendant of #{BuildDataSource.name}"
      end

      self.build_data_source = build_data_source
    end

    def list_builds(project: nil)
      return build_data_source.list_builds(project: project)
    end

    def pending_builds(project: nil)
      return build_data_source.pending_builds(project: project)
    end

    # returns a list of commit shas where the status is pending
    # and it hasn't been superceeded by a newer build
    def pending_build_shas_needing_rebuilds(project:)
      all_builds = list_builds(project: project)

      all_completed_builds_shas = all_builds
                                  .reject { |build| build.status == "pending" }
                                  .map(&:sha)
                                  .uniq

      all_pending_builds_shas_needing_rebuilds = all_builds
                                                 .select { |build| build.status == "pending" }
                                                 .map(&:sha)
                                                 .uniq
        .-(all_completed_builds_shas)

      return all_pending_builds_shas_needing_rebuilds
    end

    # Checks if the most recent build is in pending state
    def most_recent_build_in_pending_state?(project:)
      builds = list_builds(project: project)
      most_recent_build = builds.first
      return false if most_recent_build.nil?

      return most_recent_build.status == "pending"
    end

    def add_build!(project: nil, build: nil)
      build_data_source.add_build!(project: project, build: build)

      # TODO: commit changes here
    end
  end
end
