require "bcrypt"
require "fileutils"
require_relative "json_data_source"
require_relative "apple_id_data_source"
require_relative "../../shared/logging_module"
require_relative "../../shared/json_convertible"
require_relative "../../shared/models/apple_id"

module FastlaneCI
  # Mixin the JSONConvertible class for AppleID
  class AppleID
    include FastlaneCI::JSONConvertible
  end

  # Data source for apple ID backed by JSON
  class JSONAppleIDDataSource < AppleIDDataSource
    include FastlaneCI::JSONDataSource
    include FastlaneCI::Logging

    class << self
      attr_accessor :file_semaphore
    end

    # can't have us reading and writing to a file at the same time
    # TODO: currently we just have this global lock
    #   Instead we'll have multiple instances of `JSONAppleIDDataSource` objects
    #   for each project and a global one
    JSONAppleIDDataSource.file_semaphore = Mutex.new

    def after_creation(**params)
      FileUtils.mkdir_p(json_folder_path)
      logger.debug("Using folder path for Apple ID data: #{json_folder_path}")
      # load up the json file here
      # parse all data into objects so we can fail fast on error
      reload_apple_ids
    end

    def apple_ids_file_path(path: "apple_ids.json")
      return File.join(json_folder_path, path)
    end

    def apple_ids
      JSONAppleIDDataSource.file_semaphore.synchronize do
        return @apple_ids
      end
    end

    def apple_ids=(apple_ids)
      JSONAppleIDDataSource.file_semaphore.synchronize do
        content_to_store = apple_ids.map do |current_apple_id|
          current_apple_id.to_object_dictionary(ignore_instance_variables: [:@password])
        end
        File.write(apple_ids_file_path, JSON.pretty_generate(content_to_store))
      end

      # Reload the Apple IDs to sync them up with the persisted file store
      reload_apple_ids
    end

    def reload_apple_ids
      JSONAppleIDDataSource.file_semaphore.synchronize do
        unless File.exist?(apple_ids_file_path)
          @apple_ids = []
          return
        end

        @apple_ids = JSON.parse(File.read(apple_ids_file_path)).map do |apple_id_hash|
          AppleID.from_json!(apple_id_hash)
        end
      end
    end

    # TODO: this isn't threadsafe
    # def update_environment_variable!(environment_variable: nil)
    #   existing = find_environment_variable(environment_variable_key: environment_variable.key)
    #   existing.value = environment_variable.value
    # end

    def delete_apple_id!(apple_id:)
      apple_ids.delete(apple_id)
    end

    # The data source isn't responsible for checking for existing data
    # This is done so in the service
    def create_apple_id!(user:, password:, prefix: nil)
      apple_ids = self.apple_ids
      new_apple_id = AppleID.new(
        user: user,
        password: password,
        prefix: prefix
      )

      apple_ids.push(new_apple_id)
      self.apple_ids = apple_ids
      logger.debug("Added Apple ID #{new_apple_id.user}, " \
        "writing out apple_ids.json to #{apple_ids_file_path}")
      return new_apple_id
    end
  end
end
