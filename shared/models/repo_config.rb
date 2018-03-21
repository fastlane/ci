require "securerandom"
require_relative "provider_credential"

module FastlaneCI
  # Contains the metadata about a git repo
  class RepoConfig
    include FastlaneCI::Logging

    attr_accessor :id
    attr_accessor :git_url
    attr_accessor :description
    attr_accessor :name # for example: "fastlane ci app"
    attr_accessor :hidden # Do we want normal users to be able to see this?
    attr_accessor :provider_credential_type_needed # what kind of provider is needed? PROVIDER_CREDENTIAL_TYPES[]
    attr_writer :containing_path # directory containing the `local_repo_path`

    def initialize(id: nil,
                   git_url: nil,
                   provider_credential_type_needed: nil,
                   description: nil, name: nil,
                   containing_path: nil,
                   hidden: false)
      self.id = id || SecureRandom.uuid
      self.git_url = git_url
      self.description = description
      self.provider_credential_type_needed = provider_credential_type_needed
      self.name = name
      self.hidden = hidden
    end

    def local_repo_path
      File.join(self.containing_path, self.id)
    end

    # This is where we store the local git repo
    # fastlane.ci will also delete this directory if it breaks
    # and just re-clones. So make sure it's fine if it gets deleted
    # TODO: Switch to something else if we don't have write permission to this directory
    def containing_path
      @containing_path ||= File.expand_path("~/.fastlane/ci/")
    end

    # Is the repo already cloned on the local machine?
    def exists?
      File.directory?(self.local_repo_path)
    end
  end
end
