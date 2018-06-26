module FastlaneCI
  # A specific event that will cause a job to start
  class JobTrigger
    TRIGGER_TYPE = {
      commit: "commit",
      pull_request: "pull_request",
      manual: "manual",
      nightly: "nightly"
    }

    # @return [TRIGGER_TYPE]
    attr_reader :type

    # @return [String] the branch we are concerned with
    attr_reader :branch

    def initialize(type: nil, branch: nil)
      @type = type
      @branch = branch
    end
  end

  # When a pull request is created, this will trigger
  class PullRequestJobTrigger < JobTrigger
    def initialize(branch: nil)
      super(type: TRIGGER_TYPE[:pull_request], branch: branch)
    end
  end

  # When a commit happens on a branch, this will trigger
  class CommitJobTrigger < JobTrigger
    def initialize(branch: nil)
      super(type: TRIGGER_TYPE[:commit], branch: branch)
    end
  end

  # Each night, at a specific time, this will trigger
  class NightlyJobTrigger < JobTrigger
    # @return [Integer] hour of the day, like 13 (1pm)
    attr_accessor :hour

    # @return [Integer] minute of hour we wish to trigger, like 30 (30th minute)
    attr_accessor :minute

    def initialize(branch: nil, hour: nil, minute: nil)
      super(type: TRIGGER_TYPE[:nightly], branch: branch)
      self.hour = hour
      self.minute = minute
    end
  end

  # When the user wishes to trigger a job, it can be done. Most projects will have at-least this
  # If a project doesn't have a ManualJobTrigger, that means we can't trigger a job manually
  class ManualJobTrigger < JobTrigger
    def initialize(branch: nil)
      super(type: TRIGGER_TYPE[:manual], branch: branch)
    end
  end
end
