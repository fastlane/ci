require "json"
require_relative "build_data_source"
require_relative "../../shared/json_convertible"
require_relative "../../shared/logging_module"
require_relative "../../shared/models/build"

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
        build_object_hash = JSON.parse(File.read(build_path))
        build = Build.from_json!(build_object_hash)
        build.project = project # this is not part of the x.json file
        build
      end

      return most_recent_builds
    end

    def pending_builds(project: nil)
      list_builds(project: project).select { |build| build.status == "pending" }
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

      File.join(json_folder_path, "projects", project.id, "builds")
    end
  end
end
