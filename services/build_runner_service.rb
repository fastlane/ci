require_relative "../features/build_runner/fastlane_build_runner"
require_relative "../shared/models/artifact"

module FastlaneCI
  # Responsible for
  # - Manage all `TestRunner` objects that are active (either in queue or actually running)
  # - Measures the time of a `TestRunner`'s execution
  # - Stores the `Build` information in version control and triggers the report of the build status on GitHub
  #
  # TODO: move github specific stuff out into GitHubService (GitHubService right now)
  # TODO: maybe rename this to GitHubBuildRunnerService
  class BuildRunnerService
    include FastlaneCI::Logging

    attr_accessor :build_runners

    def initialize
      self.build_runners = []
    end

    def add_build_runner(build_runner: nil)
      raise "No build runner provided" unless build_runner.kind_of?(BuildRunner)

      self.build_runners << build_runner

      # TODO: not the best approach to spawn a thread
      # Use TaskQueue instead
      Thread.new do
        build_runner.start
      end
    end

    def find_build_runner(project_id: nil, build_number: nil)
      raise "You have to provide both a project and a build number" if project_id.nil? || build_number.nil?

      # Fetch all the active runners, and see if there is one WIP
      return self.build_runners.find do |build_runner|
        build_runner.project.id == project_id && build_runner.current_build.number == build_number
      end
    end
  end
end
