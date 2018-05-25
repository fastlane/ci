require_relative "api_controller"

module FastlaneCI
  # Controller for providing all data relating to system settings
  class SettingJSONController < APIController
    HOME = "/data/settings"

    get HOME do
      return Services.setting_service.settings.to_json
    end

    post HOME do
      metrics = Services.setting_service.settings.first
      metrics.value = false
      Services.setting_service.update_setting!(setting: metrics)

      return {}
    end
  end
end
