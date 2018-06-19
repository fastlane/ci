require "fileutils"
require_relative "json_data_source"
require_relative "setting_data_source"
require_relative "../../shared/logging_module"
require_relative "../../shared/json_convertible"
require_relative "../../shared/models/setting"

module FastlaneCI
  # Mixin the JSONConvertible class for Setting
  class Setting
    include FastlaneCI::JSONConvertible
  end

  # Data source for settings variables backed by JSON
  class JSONSettingDataSource < SettingDataSource
    include FastlaneCI::JSONDataSource
    include FastlaneCI::Logging

    class << self
      attr_accessor :file_semaphore
    end

    # can't have us reading and writing to a file at the same time
    # TODO: currently we just have this global lock
    #   Instead we'll have multiple instances of `JSONSettingDataSource` objects
    #   for each project and a global one
    JSONSettingDataSource.file_semaphore = Mutex.new

    def after_creation(**params)
      FileUtils.mkdir_p(json_folder_path)
      logger.debug("Using folder path for settings data: #{json_folder_path}")
      # load up the json file here
      # parse all data into objects so we can fail fast on error
      reload_settings
    end

    def setting_file_path(path: "settings.json")
      return File.join(json_folder_path, path)
    end

    # TODO: make synchronize work again
    def settings
      # JSONSettingDataSource.file_semaphore.synchronize do
      return @settings
      # end
    end

    def settings=(settings)
      JSONSettingDataSource.file_semaphore.synchronize do
        content_to_store = settings.map do |current_setting|
          current_setting.to_object_dictionary(ignore_instance_variables: [:@verify_block, :@default_value])
        end
        File.write(setting_file_path, JSON.pretty_generate(content_to_store))
      end

      # Reload the variables to sync them up with the persisted file store
      reload_settings
    end

    def reload_settings
      JSONSettingDataSource.file_semaphore.synchronize do
        @settings = AvailableSettings.available_settings

        unless File.exist?(setting_file_path)
          # No custom configuration yet
          # We still to return the defaults
          return
        end

        JSON.parse(File.read(setting_file_path)).each do |setting_hash|
          user_setting = Setting.from_json!(setting_hash)
          available_setting = find_setting(setting_key: user_setting.key)
          if available_setting
            available_setting.value = user_setting.value
          else
            raise "Could not find available_option with key #{user_setting.key}"
          end
        end
      end
    end

    # TODO: this isn't threadsafe
    def update_setting!(setting: nil)
      existing = find_setting(setting_key: setting.key)
      existing.value = setting.value
      self.settings = settings
    end

    # Finds setting with a given key
    #
    # @return [Setting]
    def find_setting(setting_key:)
      return settings.detect do |setting|
        setting.key.to_sym == setting_key.to_sym
      end
    end
  end
end
