require_relative "../shared/logging_module"
require_relative "./services"

require "xcode/install"

module FastlaneCI
  # Manages Xcode installations
  class XcodeManagerService
    include FastlaneCI::Logging

    # Keeps an a hash, the key being the Gem::Version of the Xcode version we're installing
    # and the value being the % of the download progress
    attr_accessor :installing_xcode_versions

    # @return [AppleID] The Apple ID to use to install Xcode
    attr_reader :apple_id

    # @param user [String]: the email address / username of the Apple ID to use
    def initialize(user: nil)
      user ||= ENV["XCODE_INSTALL_USER"] # if the server is launched with this ENV variable

      use_apple_id(user: user)

      @installing_xcode_versions = {}
    end

    # Change the Apple ID to be used, you have to pass either `apple_id` or `user`
    # @param apple_id [AppleID]
    # @param user [String]
    def use_apple_id(apple_id: nil, user: nil)
      # use the user (email) to identify to make sure the account is
      # persisted and can be used
      user ||= apple_id.user if apple_id

      @apple_id = Services.apple_id_service.apple_ids.find { |a| a.user == user } if user
      if self.apple_id.nil?
        # Think about the user flow on how this would be shown, we probably want to check
        # for the existance of the Apple ID earlier, and then not even show the button,
        # or make the button redirect to the Apple ID login instead
        logger.error("No registered Apple ID found with user #{user}, make sure to add your " \
                     "Apple account to fastlane.ci")
        return false
      end
      return true
    end

    # A shared reference to the `XcodeInstall::Installer` object we use
    def installer
      if @_installer.nil?
        @_installer = XcodeInstall::Installer.new
      end
      # @_installer.rm_list_cache

      return @_installer
    end

    def xcode_queue
      @_xcode_queue ||= TaskQueue::TaskQueue.new(name: "fastlane.ci Xcode queue")
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
      apple_id_credentials_block do
        installer.seedlist.reverse
      end
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
    def reset_xcode_version!
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

    def apple_id_credentials_block
      # There is no public interface in xcode-install to pass the Apple ID credentials
      # So we use environment variables to pass both the username, and the password
      ENV["XCODE_INSTALL_USER"] = apple_id.user
      ENV["XCODE_INSTALL_PASSWORD"] = apple_id.password

      yield
    ensure
      ENV.delete("XCODE_INSTALL_USER")
      ENV.delete("XCODE_INSTALL_PASSWORD")
    end

    # ###############################
    # Everything around installation
    # ###############################

    # Install a specific version of Xcode on the current machine
    # success_block is only called when no exception occured
    # only either error_block or success_block will be called
    # @param version [Gem::Version]
    def install_xcode!(version:, success_block: nil, error_block: nil)
      raise "Please only pass `Gem::Version` to `install_xcode!`" unless version.kind_of?(Gem::Version)

      apple_id_credentials_block do
        unless installer.exist?(version)
          raise "Xcode version '#{version}' is not available in the list of Xcode versions: " \
                "#{available_xcode_versions.map(&:version).join(', ')}"
        end
      end

      if installing_xcode_versions[version]
        raise "Xcode version #{version} is already being downloaded... Download couldn't be started"
      end

      logger.info("#{version} is available to be installed... putting installation process on the queue")
      # TODO: Check if installing a given Xcode version is already in the queue
      #       if it is, we need a way to append the `success` block to it

      install_xcode_task = TaskQueue::Task.new(work_block: proc {
        # There is no public interface in xcode-install to pass the Apple ID credentials
        # So we use environment variables to pass both the username, and the password
        ENV["XCODE_INSTALL_USER"] = apple_id.user
        ENV["XCODE_INSTALL_PASSWORD"] = apple_id.password
        begin
          apple_id_credentials_block do
            installer.install_version(
              # version: the version to install
              version,
              # `should_switch` is false, as we handle it on the fastlane.ci side of things, also
              #  this will create aliases which we don't need
              false,
              # `should_clean` is true, as we don't need to keep old DMG files around
              false, # false for now for faster debugging
              # `should_install` is true, as we want to not only download, but also install this version
              true,
              # `progress` We pass the custom `progress_block` instead, we don't want to show the
              #           download progress in stdout
              false,
              # `url` is nil, as we don't have a custom source
              nil,
              # `show_release_notes` is `false`, as this is a non-interactive machine
              false,
              # `progress_block` be updated on the download progress
              proc do |percent|
                installing_xcode_versions[version] = percent
              end
            )
          end
          logger.info("Successfully finished Xcode installation of version #{version}")
          success_block.call(version) if success_block
        rescue StandardError => ex
          # Handle and show error here
          logger.error(ex)
          logger.error(ex.backtrace)
          error_block.call(version, ex) if error_block
        ensure
          installing_xcode_versions.delete(version)
          ENV.delete("XCODE_INSTALL_USER")
          ENV.delete("XCODE_INSTALL_PASSWORD")
        end
      })

      xcode_queue.add_task_async(task: install_xcode_task)

      # Reference the task with the Xcode version
      installing_xcode_versions[version] = 0
    end
  end
end
