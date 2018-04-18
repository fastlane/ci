require "graphql"

module FastlaneCI
  # Definition of the different GraphQL types.
  module Types
    # Define RepoConfig as a common interface from which other
    # code hosting services inherits from.
    RepoConfigInterface = GraphQL::InterfaceType.define do
      name "RepoConfig"
      description "fastlane.ci Repository Configuration"
      field :id, !types.String
      field :git_url, types.String
      field :name, types.String
      field :enabled, types.Boolean
      field :provider_credential_type_needed, types.String
    end

    # GitHub Repository Configuration Object.
    GitHubRepoConfigType = GraphQL::ObjectType.define do
      interfaces [RepoConfigInterface]
      field :full_name, types.String
    end
  end
end
