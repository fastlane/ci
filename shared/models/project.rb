require "securerandom"

module FastlaneCI
  class Project
    # @return [GitRepoConfig] URL to the Git repo
    attr_accessor :repo_config

    # @return [String] Name of the project
    attr_accessor :project_name

    # @return [String] lane name to run
    attr_accessor :lane

    # @return [Boolean]
    attr_accessor :enabled

    # @return [String] Is a UDID so we're not open to ID guessing attacks
    attr_accessor :id

    attr_reader :current_user_has_access
    alias current_user_has_access? current_user_has_access

    def initialize(repo_config: nil, enabled: nil, project_name: nil, lane: nil, id: nil)
      self.repo_config = repo_config
      self.enabled = enabled
      self.project_name = project_name
      @current_user_has_access = current_user_has_access # @ as there is no `setter`
      self.id = id || SecureRandom.uuid
      self.lane = lane
    end
  end
end
