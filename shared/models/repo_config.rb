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

    def initialize(id: nil,
                   git_url: nil,
                   provider_credential_type_needed: nil,
                   description: nil,
                   name: nil,
                   hidden: false)
      self.id = id || SecureRandom.uuid
      self.git_url = git_url
      self.description = description
      self.provider_credential_type_needed = provider_credential_type_needed
      self.name = name
      self.hidden = hidden
    end
  end
end
