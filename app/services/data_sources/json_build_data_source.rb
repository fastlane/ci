require "json"
require_relative "build_data_source"
require_relative "../../shared/json_convertible"
require_relative "../../shared/logging_module"
require_relative "../../shared/models/build"
require_relative "../../shared/models/artifact"
require_relative "../../shared/models/artifact_provider.rb"
require_relative "../../shared/models/local_artifact_provider.rb"
require_relative "../../shared/models/gcp_artifact_provider"
require_relative "../../shared/models/git_fork_config"

module FastlaneCI
  # Mixin the JSONConvertible class for Build
  class Build
    include FastlaneCI::JSONConvertible

    def self.attribute_name_to_json_proc_map
      timestamp_to_json_proc = proc { |timestamp|
        timestamp.strftime("%s").to_i
      }
      return { :@timestamp => timestamp_to_json_proc }
    end

    def self.json_to_attribute_name_proc_map
      seconds_to_datetime_proc = proc { |seconds|
        Time.at(seconds.to_i)
      }
      return { :@timestamp => seconds_to_datetime_proc }
    end

    def self.attribute_to_type_map
      return {
        :@git_fork_config => GitForkConfig,
        :@artifacts => Artifact
      }
    end
  end

  # Mixin the JSONConvertible class for Artifact
  class Artifact
    include FastlaneCI::JSONConvertible

    def self.json_to_attribute_name_proc_map
      provider_object_to_provider = proc { |object|
        # So, there might be some chances (but it shouldn't ever happen)
        # that the Artifact's ArtifactProvider is null in the JSON, so it must be nil in the object.
        # But that means that the Artifact is unrecoverable.
        # TODO: What kind of error handling should we provide? An Artifact with nil provider is unrecoverable.
        nil if object.nil?
        provider_class = Object.const_get(object["class_name"])
        if provider_class.include?(JSONConvertible)
          provider = provider_class.from_json!(object)
          provider
        end
      }
      return { :@provider => provider_object_to_provider }
    end

    # Mixin the JSONConvertible class for GitForkConfig
    class GitForkConfig
      # See comment in git_fork_config.rb
      include FastlaneCI::JSONConvertible
    end

    def self.attribute_name_to_json_proc_map
      provider_to_provider_object = proc { |provider|
        if provider.class.include?(JSONConvertible)
          hash = provider.to_object_dictionary
          hash
        end
      }
      return { :@provider => provider_to_provider_object }
    end
  end

  # Mixin the JSONConvertible class for LocalArtifactProvider
  class LocalArtifactProvider
    include FastlaneCI::JSONConvertible
  end

  # Mixin the JSONConvertible class for GCPStorageArtifactProvider
  class GCPStorageArtifactProvider
    include FastlaneCI::JSONConvertible
  end

  # Data source for all things related to builds on the file system in JSON
  class JSONBuildDataSource < BuildDataSource
    include FastlaneCI::JSONDataSource
    include FastlaneCI::Logging

    attr_accessor :json_folder_path

    def after_creation(**params)
      logger.debug("Using folder path for build data: #{json_folder_path}")
    end

    def list_builds(project: nil)
      containing_path = builds_path(project: project)
      file_names = Dir[File.join(containing_path, "*.json")]
      build_numbers = file_names.map { |f| File.basename(f, ".*").to_i }

      build_files = build_numbers.map do |build_number|
        File.join(containing_path, "#{build_number}.json")
      end

      most_recent_builds = build_files.map do |build_path|
        begin
          build_object_hash = JSON.parse(File.read(build_path))
          build = Build.from_json!(build_object_hash)
        rescue StandardError => ex
          logger.error(ex.to_s)
          logger.error(ex.backtrace)
          raise "Error parsing build information on path '#{File.expand_path(build_path)}'"
        end

        build.update_project!(project) # this is not part of the x.json file
        build
      end

      return most_recent_builds
    end

    def pending_builds(project: nil)
      return list_builds(project: project).select { |build| build.status == "pending" }
    end

    # Add or update a build
    def add_build!(project: nil, build: nil)
      containing_path = builds_path(project: project)
      full_path = File.join(containing_path, "#{build.number}.json")

      logger.debug("Writing to '#{full_path}'")
      hash_to_store = build.to_object_dictionary(ignore_instance_variables: [:@project])
      FileUtils.mkdir_p(containing_path)
      File.write(full_path, JSON.pretty_generate(hash_to_store))
    end

    private

    def builds_path(project: nil)
      raise "No project provided: #{project}" unless project.kind_of?(FastlaneCI::Project)

      return File.join(json_folder_path, "projects", project.id, "builds")
    end
  end
end
