require_relative "../../shared/json_convertible"

module FastlaneCI
  # View model to expose the a project's lane.
  class LaneViewModel
    include FastlaneCI::JSONConvertible

    # @return [String] name of the lane
    attr_reader :name

    # @return [String] platform type (Ex. iOS)
    attr_reader :platform

    def initialize(lane_name:, lane_platform:)
      @name = lane_name
      @platform = lane_platform
    end
  end
end
