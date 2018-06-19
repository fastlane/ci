require_relative "data_sources/json_environment_variable_data_source"
require_relative "../shared/logging_module"
require_relative "./services"

module FastlaneCI
  # Provides access to environment variables
  class EnvironmentVariableService
    include FastlaneCI::Logging
    attr_accessor :environment_variable_data_source

    def initialize(environment_variable_data_source: nil)
      unless environment_variable_data_source.nil?
        unless environment_variable_data_source.class <= EnvironmentDataSource
          raise "environment_variable_data_source must be descendant of #{EnvironmentDataSource.name}"
        end
      end

      if environment_variable_data_source.nil?
        # Default to JSONEnvironmentDataSource
        # TODO: do we need `sample_data` here?
        logger.debug(
          "environment_variable_data_source is new, using `ENV[\"data_store_folder\"]` " \
          "if available, or `sample_data` folder"
        )
        data_store_folder = ENV["data_store_folder"] # you can set it at runtime!
        data_store_folder ||= File.join(FastlaneCI::FastlaneApp.settings.root, "sample_data")
        environment_variable_data_source = JSONEnvironmentDataSource.create(data_store_folder)
      end

      self.environment_variable_data_source = environment_variable_data_source
    end

    #####################################################
    # @!group Environment Variable Logic
    #####################################################

    def environment_variables
      environment_variable_data_source.environment_variables
    end

    def create_environment_variable!(key: nil, value: nil)
      key.strip!

      if environment_variable_data_source.find_environment_variable(environment_variable_key: key).nil?
        logger.info("Creating ENV variable with key #{key}")
        return environment_variable_data_source.create_environment_variable!(key: key, value: value)
      end

      logger.info("Environment Variable #{key} already exists!")
      return nil
    end

    def update_environment_variable!(environment_variable:)
      key = environment_variable.key

      if environment_variable_data_source.find_environment_variable(environment_variable_key: key).nil?
        logger.info("No existing ENV variable with key #{key}")
      end

      environment_variable_data_source.update_environment_variable!(
        environment_variable: environment_variable
      )
      # TODO: do we have to write out to the file here? Seems like it's missing
    end

    def delete_environment_variable!(environment_variable_key:)
      existing = environment_variable_data_source.find_environment_variable(
        environment_variable_key: environment_variable_key
      )
      environment_variable_data_source.delete_environment_variable!(
        environment_variable: existing
      )
    end
  end
end
