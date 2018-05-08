require_relative "../shared/logging_module"
require_relative "./services"

module FastlaneCI
  # Manages Xcode installations
  class XcodeManagerService
    def installer
      if @_installer.nil?
        @_installer = XcodeInstall::Installer.new
      end
      # @_installer.rm_list_cache

      return @_installer
    end

    # @return [XcodeInstall::Xcode]
    #   <XcodeInstall::Xcode:0x007fa1d451c390
    #     @date_modified=2015,
    #     @name="6.4",
    #     @path="/Developer_Tools/Xcode_6.4/Xcode_6.4.dmg",
    #     @url=
    #      "https://developer.apple.com/devcenter/download.action?path=/Developer_Tools/Xcode_6.4/Xcode_6.4.dmg",
    #     @version=Gem::Version.new("6.4")>,
    #
    # the resulting list is sorted with the most recent release as first element
    def available_xcode_versions
      return installer.seedlist.reverse
    end

    # @return [XcodeInstall::InstalledXcode]
    #   <XcodeInstall::InstalledXcode:0x007fc77c00f0a0
    #     @path=#<Pathname:/Applications/Xcode.app>,
    #     @bundle_version="9.2">
    #
    # Make sure to always use `.bundle_version` and not `.version`
    #
    # More methods available, like `available_simulators` and `uuid`
    def installed_xcode_versions
      return installer.installed_versions
    end

    # Switches to a given Xcode version by setting the DEVELOPER_DIR environment variable
    def switch_xcode_version!(xcode_path:)
      # It's save to say that DEVELOPER_DIR is fully managed by fastlane.ci
      # and we don't respect the user setting their own
      ENV["DEVELOPER_DIR"] = xcode_path.to_s if xcode_path
    end

    # Call this after calling `switch_xcode_version!`
    # after finishing the build
    def clear_xcode_version!
      ENV.delete("DEVELOPER_DIR")
    end

    # Run `xcode-select-p`, makes testing possible
    def xcode_select_p
      `xcode-select -p`.strip
    end

    # @return [String] The path to the currently selected Xcode
    #   e.g. "/Applications/Xcode9.2.app"
    def current_xcode_path
      path = ENV["DEVELOPER_DIR"] if ENV["DEVELOPER_DIR"].to_s.length > 0
      path ||= xcode_select_p

      # When using `xcode-select -p` the output ends with "Contents/Developer" for legacy reasons
      path = File.expand_path("../..", path) if path.end_with?("Contents/Developer")

      return path
    end

    # @return [XcodeInstall::InstalledXcode] of the currently selected Xcode
    def current_xcode
      return XcodeInstall::InstalledXcode.new(current_xcode_path)
    end

    # Detect the current Xcode version
    # @return [Gem::Version] e.g. `Gem::Version.new("9.2")`
    def current_xcode_version
      return Gem::Version.new(current_xcode.fetch_version)
    end
  end
end
