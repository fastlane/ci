require_relative "api_controller"

module FastlaneCI
  # Controller for providing all data relating to system settings
  class SettingJSONController < APIController
    HOME = "/data/settings"

    get HOME do
      return json(Services.setting_service.settings)
    end

    post "#{HOME}/:setting_key" do
      key = params[:setting_key]
      value = params[:value]

      setting = Services.setting_service.find_setting(setting_key: key.to_sym)

      if setting.nil?
        json_error!(
          error_message: "`#{params[:setting_key]}` not found.",
          error_key: "InvalidParameter.KeyNotFound",
          error_code: 404
        )
      end

      # TODO: security aspect, how do we make sure this can't be abused?
      # We don't want to hash/encrypt all of them, as this would make it harder for
      # people to manually update those files
      setting.value = value
      Services.setting_service.update_setting!(setting: setting)

      return json({ status: :success })
    end

    delete "#{HOME}/:setting_key" do
      begin
        # TODO: security for parameters as in the POST code
        Services.setting_service.reset_setting!(setting_key: params[:setting_key])
        return json({ status: :success })
      rescue SettingServiceKeyNotFoundError
        json_error!(
          error_message: "`#{params[:setting_key]}` not found.",
          error_key: "InvalidParameter.KeyNotFound",
          error_code: 404
        )
      end
    end
  end
end
