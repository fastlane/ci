require_relative "../../shared/models/artifact"
require_relative "../../shared/json_convertible"

module FastlaneCI
  # View model to expose the detailed info about an artifact.
  class ArtifactViewModel
    include FastlaneCI::JSONConvertible

    # @return [UUID] The id of the artifact.
    attr_reader :id

    # String that refers to the kind of data that the Artifact represents
    # (i.e., ipa, apk, log, SCAN_DERIVED_DATA_PATH, etc.)
    # @return [String] The type or kind of artifact.
    attr_reader :type

    # @return [String] The reference to the artifact to a certain ArtifactProvider
    attr_reader :reference

    # @return [ArtifactProvider] The reference to the ArtifactProvider that stores the artifact
    attr_reader :provider

    # @return An URI to download the given artifact
    attr_reader :uri

    def initialize(artifact:, uri:)
      raise "Incorrect object type. Expected Artifact, got #{artifact.class}" unless artifact.kind_of?(Artifact)

      @id = artifact.id
      @type = artifact.type
      @reference = artifact.reference
      @provider = artifact.provider
      @uri = uri
    end
  end
end
