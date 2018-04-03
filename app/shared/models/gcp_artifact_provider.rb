require_relative "artifact_provider"
require_relative "artifact"
require_relative "build"
require_relative "project"

require "google/cloud/storage"
require "pathname"

module FastlaneCI
  # ArtifactProvider backed by a Google Cloud Platform Storage bucket.
  class GCPStorageArtifactProvider < ArtifactProvider
    class << self
      # Provide a simple default root_path for users that don't want much configuration.
      def root_browser
        "https://console.cloud.google.com/storage/browser/"
      end
    end

    # @return [String]
    attr_reader :cloud_project

    # @return [String]
    attr_reader :json_keyfile_path

    # @return [String]
    attr_reader :bucket_name

    # @return [String] The class of the provider
    attr_reader :class_name

    # @return [Google::Cloud::Storage]
    attr_accessor :storage

    # @return [Google::Cloud::Storage::Bucket]
    attr_accessor :bucket

    def initialize(cloud_project: nil, json_keyfile_path: nil, bucket_name: nil)
      @cloud_project = cloud_project
      @json_keyfile_path = json_keyfile_path
      @bucket_name = bucket_name
      @class_name = self.class.name.to_s
    end

    def init_storage!
      # TODO: This will break when google-cloud-storage is updated.
      # For now we have set the version at: gem "google-cloud-storage", "~> 1.5.0"
      # Because _fastlane_ has a fixed dependency on "google-api-client"
      # Ideally, in a near future this should be upgraded which may lead to breaking syntax.
      self.storage = Google::Cloud::Storage.new(
        project: cloud_project,
        keyfile: File.expand_path(json_keyfile_path)
      )
      self.bucket = storage.bucket(bucket_name)
      permissions = bucket.test_permissions("storage.objects.create", "storage.objects.get")

      unless permissions.include?("storage.objects.create") && permissions.include?("storage.objects.get")
        # rubocop:disable Metrics/LineLength
        raise "The credentials provided by #{File.basename(json_keyfile_path)} are insufficient to perform needed actions by the provider, needed: 'storage.objects.create', 'storage.objects.get' got #{permissions}."
        # rubocop:enable Metrics/LineLength
      end
    end

    def store!(artifact:, build:, project:)
      raise "Artifact to store was not provided or wrong type provided" unless artifact&.is_a?(Artifact)
      raise "Build was not provided or wrong type provided" unless build&.is_a?(Build)
      raise "Project was not provided or wrong type provided" unless project&.is_a?(Project)

      init_storage!

      original_artifact_reference = Pathname.new(artifact.reference)

      unless File.exist?(original_artifact_reference)
        raise "Artifact referenced at #{original_artifact_reference} was not found"
      end

      new_artifact_reference = File.join(
        project.id,
        build.number.to_s,
        artifact.type,
        File.basename(original_artifact_reference)
      )

      file = bucket.create_file(original_artifact_reference.to_s, new_artifact_reference)

      raise "File couldn't be created" if file.nil?

      artifact.reference = new_artifact_reference
      artifact.provider = self
      return artifact # This is the Artifact that we will store in the build.
    end

    def retrieve!(artifact:)
      raise "Artifact to store was not provided or wrong type provided" unless artifact&.is_a?(Artifact)

      init_storage!

      file = bucket.file(artifact.reference)
      raise "File pointed by #{artifact.reference} was not found on the configured bucket" if file.nil?

      # TODO: For now is ok to return just the link to the browser in the GCP Console itself,
      # this should be revisited later to address how we generate permanent public links to the artifact
      # if the bucket is public (read-public) or expiring links for private buckets.
      return "#{self.class.root_browser}#{bucket_name}/#{artifacts.first.reference.split('/')[0..-2].join('/')}"
    end
  end
end
