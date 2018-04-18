require "graphql"

module FastlaneCI
  # Definition of the different GraphQL types.
  module Types
    CommitJobTriggerType = GraphQL::ObjectType.define do
      name "CommitJobTrigger"
      field :branch, !types.String
    end

    NightlyJobTrigger = GraphQL::ObjectType.define do
      name "NightlyJobTrigger"
      field :branch, !types.String
      field :hour, types.Int
      field :minute, types.Int
    end

    ManualJobTrigger = GraphQL::ObjectType.define do
      name "CommitJobTrigger"
      field :branch, !types.String
    end

    JobTriggerType = GraphQL::UnionType.define do
      name "JobTrigger"
      possible_types [CommitJobTriggerType, NightlyJobTrigger, ManualJobTrigger]
    end
  end
end
