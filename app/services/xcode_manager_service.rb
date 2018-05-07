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
  end
end
