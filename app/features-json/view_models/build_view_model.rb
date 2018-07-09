require_relative "../../shared/models/build"
require_relative "../../shared/json_convertible"

module FastlaneCI
  # View model to expose the detailed info about a build.
  class BuildViewModel
    include FastlaneCI::JSONConvertible

    # The project ID this build is associated with
    attr_reader :project_id

    # @return [Integer]
    attr_reader :number

    # @return [String]
    attr_reader :status

    # @return [DateTime] Start time
    attr_reader :timestamp

    # @return [Integer]
    attr_reader :duration

    # @return [String] An optional message to go along with the build, will show up as part of the build status on
    # GitHub
    attr_reader :description

    # @return [String] the trigger type that triggered this particular build
    attr_reader :trigger

    # @return [String] the lane name (without platform) that was used for this particular build
    attr_reader :lane

    # @return [String] the platform name (without lane) that was used for this particular build
    attr_reader :platform

    # @return [Hash] the parameters that were passed on this particular build
    # TODO: We currently don't use/store/support parameters (yet) https://github.com/fastlane/ci/issues/783
    attr_reader :parameters

    # @return [Hash] a hash containing the version numbers for each build tool that was used
    attr_reader :build_tools

    # @return [String] The git URL
    attr_reader :clone_url

    # @return [String] The git branch
    attr_reader :branch

    # @return [String] The git ref
    attr_reader :ref

    # @return [String] The git sha
    attr_reader :sha

    # @return [Array] An array of artifacts associated with this build
    attr_reader :artifacts

    def initialize(build:)
      @project_id = build.project.id
      @number = build.number
      @status = build.status
      @timestamp = build.timestamp
      @duration = build.duration
      @description = build.description
      @trigger = build.trigger
      @lane = build.lane
      @platform = build.platform
      @parameters = build.parameters
      @build_tools = build.build_tools
      @clone_url = build.git_fork_config.clone_url
      @branch = build.git_fork_config.branch
      @ref = build.git_fork_config.ref
      @sha = build.git_fork_config.sha

      @artifacts = build.artifacts.collect do |current_artifact|
        {
          id: current_artifact.id,
          type: current_artifact.type,
          provider: current_artifact.provider.class_name
        }
      end

      # artifacts e.g.
      # [
      #   {
      #     "id": "4f15114a-25b2-4072-be56-dafa81b90821",
      #     "type": "fastlane.log",
      #     "provider": "FastlaneCI::LocalArtifactProvider"
      #   },
      #   {
      #     "id": "9c8b9bc2-52b6-4e23-b815-83ee7307aada",
      #     "type": "SCAN_DERIVED_DATA_PATH",
      #     "provider": "FastlaneCI::LocalArtifactProvider"
      #   }
      # ]
    end
  end
end
