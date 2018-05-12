require "bcrypt"
require "fileutils"
require_relative "json_data_source"
require_relative "environment_data_source"
require_relative "../../shared/logging_module"
require_relative "../../shared/json_convertible"
require_relative "../../shared/models/environment_variable"

module FastlaneCI
  # Mixin the JSONConvertible class for EnvironmentVariable
  class EnvironmentVariable
    include FastlaneCI::JSONConvertible
  end

  # Data source for environment variables backed by JSON
  class JSONEnvironmentDataSource < EnvironmentDataSource
    include FastlaneCI::JSONDataSource
    include FastlaneCI::Logging

    class << self
      attr_accessor :file_semaphore
    end

    # can't have us reading and writing to a file at the same time
    # TODO: currently we just have this global lock
    #   Instead we'll have multiple instances of `JSONEnvironmentVariableDataSource` objects
    #   for each project and a global one
    JSONEnvironmentDataSource.file_semaphore = Mutex.new

    def after_creation(**params)
      FileUtils.mkdir_p(json_folder_path)
      logger.debug("Using folder path for environment data: #{json_folder_path}")
      # load up the json file here
      # parse all data into objects so we can fail fast on error
      reload_environment
    end

    def environment_file_path(path: "environment_variables.json")
      return File.join(json_folder_path, path)
    end

    def environment_variables
      JSONEnvironmentDataSource.file_semaphore.synchronize do
        return @environment
      end
    end

    def environment_variables=(environment_variables)
      JSONEnvironmentDataSource.file_semaphore.synchronize do
        content_to_store = environment_variables.map do |current_environment_variable|
          current_environment_variable.to_object_dictionary(ignore_instance_variables: [:@value])
        end
        File.write(environment_file_path, JSON.pretty_generate(content_to_store))
      end

      # Reload the variables to sync them up with the persisted file store
      reload_environment
    end

    def reload_environment
      JSONEnvironmentDataSource.file_semaphore.synchronize do
        unless File.exist?(environment_file_path)
          @environment = []
          return
        end

        @environment = JSON.parse(File.read(environment_file_path)).map do |environment_variable_hash|
          EnvironmentVariable.from_json!(environment_variable_hash)
        end
      end
    end

    # TODO: this isn't threadsafe
    def update_environment_variable!(environment_variable: nil)
      existing = find_environment_variable(environment_variable_key: environment_variable.key)
      existing.value = environment_variable.value
    end

    def delete_environment_variable!(environment_variable: nil)
      environment_variables.delete(environment_variable)
    end

    # The data source isn't responsible for checking for existing data
    # This is done so in the service
    def create_environment_variable!(key: nil, value: nil)
      environment_variables = self.environment_variables
      new_environment_variable = EnvironmentVariable.new(
        key: key,
        value: value
      )

      environment_variables.push(new_environment_variable)
      self.environment_variables = environment_variables
      logger.debug("Added ENV variable #{new_environment_variable.key}, " \
        "writing out environment_variables.json to #{environment_file_path}")
      return new_environment_variable
    end

    # Finds an environment variable with a given key
    #
    # @return [EnvironmentVariable]
    def find_environment_variable(environment_variable_key:)
      return environment_variables.detect do |environment_variable|
        environment_variable.key == environment_variable_key
      end
    end
  end
end
