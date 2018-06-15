module FastlaneCI
  # This class is responsible for defining all the available
  # system-wide fastlane.ci settings
  class AvailableSettings
    def self.available_settings
      [
        Setting.new(
          key: :metrics_enabled,
          default_value: true,
          description: "Set this to false to opt out of all metrics tracking, more information on " \
                       "https://github.com/fastlane/ci"
        ),
        Setting.new(
          key: :default_apple_id,
          default_value: nil,
          description: "The default Apple ID to use for certain tasks, like installing new versions of Xcode",
          verify_block: proc do |value|
            apple_id = Services.apple_id_service.apple_ids.find { |a| a.user == value }
            raise "Couldn't find Apple ID with email '#{value}'" if apple_id.nil?
          end
        )
      ]
    end
  end
end
