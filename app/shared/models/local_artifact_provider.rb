require_relative "artifact_provider"
require_relative "artifact"
require_relative "build"
require_relative "project"

require "pathname"

module FastlaneCI
  # ArtifactProvider backed by a local filesystem.
  class LocalArtifactProvider < ArtifactProvider
    class << self
      # Provide a simple default root_path for users that don't want much configuration.
      def default_root_path
        Pathname.new(File.expand_path("~/.fastlane/ci/")).join("artifacts")
      end
    end

    # @return [String] The class of the provider
    attr_reader :class_name

    def initialize
      @class_name = self.class.name.to_s
      FileUtils.mkdir_p(LocalArtifactProvider.default_root_path) \
        unless File.directory?(LocalArtifactProvider.default_root_path)
    end

    def store!(artifact:, build:, project:)
      raise "Artifact to store was not provided or wrong type provided" unless artifact&.is_a?(Artifact)
      raise "Build was not provided or wrong type provided" unless build&.is_a?(Build)
      raise "Project was not provided or wrong type provided" unless project&.is_a?(Project)

      if LocalArtifactProvider.default_root_path.kind_of?(Pathname)
        root_path = LocalArtifactProvider.default_root_path
      else
        root_path = Pathname.new(LocalArtifactProvider.default_root_path)
      end

      artifact_path = root_path.join(project.id, build.number.to_s)

      FileUtils.mkdir_p(artifact_path) unless File.directory?(artifact_path)

      original_artifact_reference = Pathname.new(artifact.reference)

      unless File.exist?(original_artifact_reference)
        raise "Artifact not found on provided path #{original_artifact_reference}"
      end

      new_artifact_reference = artifact_path.join(artifact.type)

      FileUtils.mkdir_p(new_artifact_reference) unless File.directory?(new_artifact_reference)

      file_name = File.basename(original_artifact_reference)

      FileUtils.mv(original_artifact_reference, new_artifact_reference.join(file_name))

      artifact.reference = new_artifact_reference.join(file_name).relative_path_from(root_path).to_s
      artifact.provider = self
      artifact # This is the Artifact that we will store in the build.
    end

    def retrieve!(artifact:)
      raise "Artifact to store was not provided or wrong type provided" unless artifact&.is_a?(Artifact)

      if File.exist?(artifact.reference)
        artifact_reference = artifact.reference
      else
        artifact_reference = File.join(LocalArtifactProvider.default_root_path, artifact.reference)
      end

      unless File.exist?(artifact_reference)
        raise "#{self.class.name} needs an existing file in #{artifact_reference}, but it was not found"
      end

      return artifact_reference
    end
  end
end
