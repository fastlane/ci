module FastlaneCI
  # Definition of the different GraphQL types.
  module Types
    # Define ArtifactProvider as a common interface from which other
    # providers can inherit from.
    ArtifactProviderInterface = GraphQL::InterfaceType.define do
      name "ArtifactProvider"
      description "fastlane.ci Artifact Provider"
      field :type, !types.String, property: :class_name
    end
  end
end
