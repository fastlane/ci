require "credentials_manager/account_manager"
require_relative "data_sources/json_apple_id_data_source"

module FastlaneCI
  # Responsible for managing the Apple ID credentials
  # Those are needed for various tasks, including:
  #   - Download new versions of Xcode
  #   - Uploading binaries
  #   - Accessing code signing assets
  #
  class AppleIDService
    include FastlaneCI::Logging

    attr_accessor :apple_id_data_source

    def initialize(apple_id_data_source: nil)
      unless apple_id_data_source.nil?
        unless apple_id_data_source.class <= AppleIDDataSource
          raise "apple_id_data_source must be descendant of #{AppleIDDataSource.name}"
        end
      end

      if apple_id_data_source.nil?
        # Default to AppleIDDataSource
        # TODO: do we need `sample_data` here?
        logger.debug(
          "apple_id_data_source is new, using `ENV[\"data_store_folder\"]` " \
          "if available, or `sample_data` folder"
        )
        data_store_folder = ENV["data_store_folder"] # you can set it at runtime!
        data_store_folder ||= File.join(FastlaneCI::FastlaneApp.settings.root, "sample_data")
        apple_id_data_source = AppleIDDataSource.create(data_store_folder)
      end

      self.apple_id_data_source = apple_id_data_source
    end

    #####################################################
    # @!group Apple ID Logic
    #####################################################

    def apple_ids
      apple_id_data_source.apple_ids
    end

    def create_apple_id!(user:, password:, prefix: nil)
      user.strip!
      return apple_id_data_source.create_apple_id!(user: user, password: password, prefix: prefix)

      # TODO: add error handling
      # if apple_id_data_source.find_environment_variable(environment_variable_key: key).nil?
      #   logger.info("Creating ENV variable with key #{key}")
      #   return apple_id_data_source.create_apple_id!(user: user, password: password, prefix: prefix)
      # end
      # logger.info("Apple ID #{user} already exists!")
      # return nil
    end

    # If we need these methods, we can copy the structure from `EnvironmentVariableService`
    # def update_apple_id!(apple_id:)
    # def delete_apple_id!(apple_id:)
  end
end
