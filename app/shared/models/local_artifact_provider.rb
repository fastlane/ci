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

    # @return [Pathname]
    attr_accessor :root_path

    # @return [String] The class of the provider
    attr_reader :class_name

    def initialize(root_path: LocalArtifactProvider.default_root_path)
      self.root_path = root_path
      @class_name = self.class.name.to_s
      FileUtils.mkdir_p(root_path) unless File.directory?(root_path)
    end

    def store!(artifact: nil, build: nil, project: nil)
      raise "Artifact to store was not provided or wrong type provided" unless artifact&.is_a?(Artifact)
      raise "Build was not provided or wrong type provided" unless build&.is_a?(Build)
      raise "Project was not provided or wrong type provided" unless project&.is_a?(Project)

      self.root_path = Pathname.new(root_path) unless root_path.kind_of?(Pathname)

      artifact_path = root_path.join(project.id, build.number.to_s)

      FileUtils.mkdir_p(artifact_path) unless File.directory?(artifact_path)

      original_artifact_reference = Pathname.new(artifact.reference)

      raise "Artifact reference not found." unless File.exist?(original_artifact_reference)

      new_artifact_reference = artifact_path.join(artifact.type)

      FileUtils.mkdir_p(new_artifact_reference) unless File.directory?(new_artifact_reference)

      file_name = File.basename(original_artifact_reference)

      FileUtils.mv(original_artifact_reference, new_artifact_reference.join(file_name))

      artifact.reference = new_artifact_reference.join(file_name)
      artifact.provider = self
      artifact # This is the Artifact that we will store in the build.
    end

    def retrieve!(artifact: nil)
      raise "Artifact to store was not provided or wrong type provided" unless artifact&.is_a?(Artifact)
      raise "#{self.class.name} needs an existing file in #{artifact.reference}, but it was not found" unless File.exist?(artifact.reference)

      return artifact.reference
    end
  end
end
