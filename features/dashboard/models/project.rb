module FastlaneCI
  class Project < ConfigBase
    # @return [String] URL to the Git repo
    attr_accessor :repo_url

    # @return [String] Name of the project
    attr_accessor :project_name

    # @return [Boolean]
    attr_accessor :enabled

    # @return [Array] A list of builds
    attr_reader :builds

    def attributes_to_persist
      super + [
        :repo_url,
        :enabled,
        :project_name
      ]
    end

    def initialize(repo_url: nil, enabled: nil, project_name: nil)
      self.repo_url = repo_url
      self.enabled = enabled
      self.project_name = project_name
    end
  end
end
