require "json"
require_relative "build_data_source"
require_relative "../../shared/logging_module"
require_relative "../../shared/models/build"
require_relative "../../shared/models/artifact"
require_relative "../../shared/models/artifact_provider.rb"
require_relative "../../shared/models/local_artifact_provider.rb"
require_relative "../../shared/models/gcp_artifact_provider"

module FastlaneCI
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
          logger.debug(ex.to_s)
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
