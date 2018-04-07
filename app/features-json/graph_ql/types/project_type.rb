require_relative "./job_trigger_type"

require "graphql"

module FastlaneCI
  # Definition of the different GraphQL types.
  module Types
    # TODO: [WIP] We don't include nested Project's properties for now.
    ProjectType = GraphQL::ObjectType.define do
      name "Project"
      description "fastlane.ci Project"
      field :id, !types.String
      field :name, types.String, property: :project_name
      field :enabled, types.Boolean
      field :platform, types.String
      field :lane, types.String
      field :job_triggers, types[Types::JobTriggerType]
    end
  end
end
