require_relative "./job_trigger_type"
require_relative "./repo_config_type"

require "graphql"

module FastlaneCI
  # Definition of the different GraphQL types.
  module Types
    ProjectType = GraphQL::ObjectType.define do
      name "Project"
      description "fastlane.ci Project"
      field :id, !types.String
      field :name, types.String, property: :project_name
      field :enabled, types.Boolean
      field :platform, types.String
      field :lane, types.String
      field :job_triggers, types[Types::JobTriggerType]
      field :repo_config, Types::RepoConfigInterface
    end
  end
end
