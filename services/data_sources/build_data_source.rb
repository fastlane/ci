require "json"

require_relative "../../shared/logging_module"
require_relative "../../shared/json_convertible"

module FastlaneCI
  # Mixin the JSONConvertible class for Build
  class Build
    include FastlaneCI::JSONConvertible
  end

  # Data source for all things related to builds
  # on the file system
  class BuildDataSource
    include FastlaneCI::Logging

    attr_accessor :json_folder_path

    def initialize(json_folder_path: nil)
      raise "json_folder_path has to be provided" if json_folder_path.to_s.length == 0
      @json_folder_path = json_folder_path
    end

    def builds_path(project: nil)
      raise "No project provided: #{project}" unless project.kind_of?(FastlaneCI::Project)

      File.join(self.json_folder_path, "projects", project.id, "builds")
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

    # Add or update a build
    def add_build!(project: nil, build: nil)
      containing_path = builds_path(project: project)
      full_path = File.join(containing_path, "#{build.number}.json")

      puts("Writing to '#{full_path}'")
      hash_to_store = build.to_object_dictionary(ignore_instance_variables: [:@project])
      FileUtils.mkdir_p(containing_path)
      File.write(full_path, JSON.pretty_generate(hash_to_store))
    end
  end
end
