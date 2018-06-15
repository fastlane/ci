require_relative "data_sources/json_setting_data_source"
require_relative "../shared/logging_module"
require_relative "../shared/available_settings"
require_relative "./services"

module FastlaneCI
  class SettingServiceKeyNotFoundError < FastlaneCIError
  end

  # Provides access to system settings
  class SettingService
    include FastlaneCI::Logging
    attr_accessor :setting_data_source

    def initialize(setting_data_source: nil)
      unless setting_data_source.nil?
        unless setting_data_source.class <= SettingDataSource
          raise "setting_data_source must be descendant of #{SettingDataSource.name}"
        end
      end

      if setting_data_source.nil?
        # Default to JSONSettingDataSource
        # TODO: do we need `sample_data` here?
        logger.debug(
          "setting_data_source is new, using `ENV[\"data_store_folder\"]` " \
          "if available, or `sample_data` folder"
        )
        data_store_folder = ENV["data_store_folder"] # you can set it at runtime!
        data_store_folder ||= File.join(FastlaneCI::FastlaneApp.settings.root, "sample_data")
        setting_data_source = JSONSettingDataSource.create(data_store_folder)
      end

      self.setting_data_source = setting_data_source
    end

    #####################################################
    # @!group Settings Logic
    #####################################################

    def settings
      return setting_data_source.settings
    end

    def find_setting(setting_key:)
      return setting_data_source.find_setting(setting_key: setting_key)
    end

    def reset_setting!(setting_key:)
      setting = setting_data_source.find_setting(setting_key: setting_key)
      raise SettingServiceKeyNotFoundError if setting.nil?

      setting.reset!
      setting_data_source.update_setting!(setting: setting)
      return true
    end

    # TODO: think more about error handling
    # 1) key not found
    # 2) other errors
    def update_setting!(setting:)
      key = setting.key

      if setting_data_source.find_setting(setting_key: key).nil?
        raise SettingServiceKeyNotFound
      end

      setting_data_source.update_setting!(setting: setting)
    end
  end
end
