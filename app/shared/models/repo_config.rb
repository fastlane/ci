require "securerandom"
require_relative "provider_credential"

module FastlaneCI
  # Contains the metadata about a git repo
  class RepoConfig
    include FastlaneCI::Logging

    attr_reader :id
    attr_reader :git_url
    attr_reader :description
    attr_reader :name # for example: "fastlane ci app"
    attr_reader :hidden # Do we want normal users to be able to see this?
    attr_reader :provider_credential_type_needed # what kind of provider is needed? PROVIDER_CREDENTIAL_TYPES[]

    def initialize(
      id: nil,
      git_url: nil,
      provider_credential_type_needed: nil,
      description: nil,
      name: nil,
      hidden: false
    )
      @id = id || SecureRandom.uuid
      @git_url = git_url
      @description = description
      @provider_credential_type_needed = provider_credential_type_needed
      @name = name
      @hidden = hidden
    end

    # Public link to remote commit
    def link_to_remote_commit(sha)
      not_implemented(__method__)
    end
  end
end
