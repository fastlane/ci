require "securerandom"
require_relative "repo_config"
require_relative "provider_credential"

module FastlaneCI
  # Contains the metadata about a git repo
  class GitRepoConfig < RepoConfig
    include FastlaneCI::Logging

    attr_accessor :full_name # GitHub full_name, like fastlane/ci (vs just `ci`)

    def initialize(id: nil,
                   git_url: nil,
                   description: nil,
                   name: nil,
                   full_name: nil,
                   hidden: false)
      super(
        id: id,
        git_url: git_url,
        provider_credential_type_needed: FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github],
        description: description,
        name: name,
        hidden: hidden
      )

      self.full_name = full_name
    end

    def self.from_octokit_repo!(repo: nil)
      repo_config = GitRepoConfig.new(
        git_url: repo[:html_url],
        description: repo[:description],
        name: repo[:name],
        full_name: repo[:full_name]
      )
      return repo_config
    end
  end
end
