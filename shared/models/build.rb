module FastlaneCI
  # Represents a build, part of a project, usually many builds per project
  class Build
    BUILD_STATUSES = [
      :success,
      :pending,
      :failure
    ]

    # A reference to the project this build is associated with
    attr_accessor :project

    # @return [String] UDID to identify the build
    attr_accessor :id

    # @return [Integer]
    attr_accessor :number

    # @return [String]
    attr_reader :status

    # @return [DateTime] Start time
    attr_accessor :timestamp

    # @return [Integer]
    attr_accessor :duration

    # @return [String] The git sha of the commit this build was run for
    attr_accessor :sha

    def initialize(project: nil, number: nil, status: nil, timestamp: nil, duration: nil, sha: nil, id: nil)
      self.project = project
      self.number = number
      self.status = status
      self.timestamp = timestamp
      self.duration = duration
      self.sha = sha
      self.id = id || SecureRandom.uuid
    end

    def status=(new_value)
      return if new_value.nil? # as during init we might init with 0 when filling in JSON values
      new_value = new_value.to_sym
      raise "Invalid build status '#{new_value}'" unless BUILD_STATUSES.include?(new_value)
      @status = new_value
    end
  end
end
