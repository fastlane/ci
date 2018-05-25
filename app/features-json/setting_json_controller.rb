require_relative "api_controller"

module FastlaneCI
  # Controller for providing all data relating to system settings
  class SettingJSONController < APIController
    HOME = "/data/settings"

    get HOME do
      return json(Services.setting_service.settings)
    end

    post HOME do
      metrics_setting = Services.setting_service.find_setting(setting_key: :metrics_enabled)
      metrics_setting.value = false
      Services.setting_service.update_setting!(setting: metrics_setting)

      return json({ status: :success })
    end
  end
end
