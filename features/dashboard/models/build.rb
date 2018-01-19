module FastlaneCI
  # Represents a build, part of a project, usually many builds per project
  # TODO: This class is currently only full of dummy data
  # We don't actually persist or load Build objects from anywhere
  class Build
    BUILD_STATUSES = [
      :success,
      :in_progress,
      :failure
    ]

    # A reference to the project this build is associated with
    attr_accessor :project

    # @return [Integer]
    attr_accessor :number

    # @return [String]
    attr_accessor :status

    # @return [DateTime]
    attr_accessor :timestamp

    def initialize(project: nil, number: nil, status: nil, timestamp: nil)
      self.project = project
      self.number = number
      self.status = status
      self.timestamp = timestamp
    end

    def status=(new_value)
      raise "Invalid build status '#{status}'" unless BUILD_STATUSES.include?(new_value)
      @status = new_value
    end
  end
end
