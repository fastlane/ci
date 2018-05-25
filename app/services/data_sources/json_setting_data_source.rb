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

    def settings
      JSONSettingDataSource.file_semaphore.synchronize do
        return @settings
      end
    end

    def settings=(settings)
      JSONSettingDataSource.file_semaphore.synchronize do
        content_to_store = settings.map do |current_setting|
          current_setting.to_object_dictionary(ignore_instance_variables: :verify_block)
        end
        File.write(setting_file_path, JSON.pretty_generate(content_to_store))
      end

      # Reload the variables to sync them up with the persisted file store
      reload_settings
    end

    def reload_settings
      JSONSettingDataSource.file_semaphore.synchronize do
        unless File.exist?(setting_file_path)
          @settings = []
          return
        end

        @settings = JSON.parse(File.read(setting_file_path)).map do |setting_hash|
          Setting.from_json!(setting_hash)
        end
      end
    end

    # TODO: this isn't threadsafe
    def update_setting!(setting: nil)
      existing = find_setting(setting_key: setting.key)
      existing.value = setting.value
      self.settings = settings
    end

    # TODO: provide a `reset_setting` method

    # Finds setting with a given key
    #
    # @return [Setting]
    def find_setting(setting_key:)
      return settings.detect do |setting|
        setting.key == setting_key
      end
    end
  end
end
