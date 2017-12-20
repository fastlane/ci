module FastlaneCI
  class Project < ConfigBase
    # @return [String] URL to the Git repo
    attr_accessor :repo_url

    # @return [Boolean]
    attr_accessor :enabled

    # @return [Array] A list of builds 
    attr_reader :builds

    def attributes_to_persist
      [
        :repo_url,
        :enabled
      ]
    end

    def initialize(repo_url: nil, enabled: nil)
      self.repo_url = repo_url
      self.enabled = enabled
    end
  end
end
