require "securerandom"

module FastlaneCI
  class Project < ConfigBase
    # @return [String] URL to the Git repo
    attr_accessor :repo_url

    # @return [String] Name of the project
    attr_accessor :project_name

    # @return [Boolean]
    attr_accessor :enabled

    attr_accessor :id

    # @return [Boolean] Does the currently logged in user have access to this
    #   repo? This value can't be changed, as it depends on the GitHub permission system
    attr_reader :current_user_has_access
    alias current_user_has_access? current_user_has_access

    # @return [Array] A list of builds
    attr_reader :builds

    def attributes_to_persist
      super + [
        :repo_url,
        :enabled,
        :project_name,
        :id
      ]
    end

    def initialize(repo_url: nil, enabled: nil, project_name: nil, id: nil, current_user_has_access: nil)
      self.repo_url = repo_url
      self.enabled = enabled
      self.project_name = project_name
      @current_user_has_access = current_user_has_access # @ as there is no `setter`
      self.id = id || SecureRandom.uuid
    end
  end
end
