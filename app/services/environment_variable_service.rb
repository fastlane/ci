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
        environment_variable_data_source = JSONEnvironmentDataSource.create(json_folder_path: data_store_folder)
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
      value.strip!

      # unless environment_variable_service.user_exist?(email: email)
      logger.debug("Creating ENV variable with key #{key}")
      return environment_variable_data_source.create_environment_variable!(key: key, value: value)
      # end

      # logger.debug("Account #{email} already exists!")
      return nil
    end

    # TODO: finish the items below - taken from user_service
    # def update_user!(user: nil)
    #   success = environment_variable_data_source.update_user!(user: user)
    #   if success
    #     # TODO: remove this message if https://github.com/fastlane/ci/issues/292 is fixed
    #     # rubocop:disable Metrics/LineLength
    #     logger.info("Updated user #{user.email}, that means you should call `find_user(id:)` see https://github.com/fastlane/ci/issues/292")
    #     # rubocop:enable Metrics/LineLength
    #   end
    #   return success
    # end

    # def delete_environment_variable!(environment_variable: nil)
    #   environment_variable_data_source.delete_environment_variable!(environment_variable: environment_variable)
    # end

    # # @return [User]
    # def find_user(id: nil)
    #   return environment_variable_data_source.find_user(id: id)
    # end

    protected

    # Not sure if this must be here or not, but we can open a discussion on this.
    # TODO: this method still needed?
    def commit_repo_changes!(message: nil, file_to_commit: nil)
      Services.configuration_git_repo.commit_changes!(commit_message: message, file_to_commit: file_to_commit)
    end
  end
end
