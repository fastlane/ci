require_relative "../shared/logging_module"
require_relative "../services/services"

require "rubygems/spec_fetcher"
require "rubygems/command_manager"

module FastlaneCI
  # Self-update fastlane.ci, this is called either on manual
  # user action, or through a background worker
  class UpdateFastlaneCIService
    include FastlaneCI::Logging

    GEM_NAME = "fastlane_ci"

    # Trigger an update for fastlane.ci
    # this method will automatically wait for all builds to finish
    def update_fastlane_ci
      loop do
        break if all_builds_complete? && all_workers_idle?
        logger.debug("Waiting for builds/workers to be complete to update fastlane.ci")
        sleep(5)
      end

      # TODO: Kill all workers here, as we're gonna restart the whole server
      logger.info("Starting update of fastlane.ci")

      execute_update
    end

    private

    def all_builds_complete?
      return true
      # TODO
    end

    def all_workers_idle?
      return true
      # TODO
    end

    def execute_update
      tools_to_update = [GEM_NAME]
      updater = Gem::CommandManager.instance[:update]
      cleaner = Gem::CommandManager.instance[:cleanup]

      gem_dir = ENV["GEM_HOME"] || Gem.dir
      sudo_needed = !File.writable?(gem_dir)

      if sudo_needed
        # TODO: update the instructions below
        logger.info("It seems that your Gem directory is not writable by your current user.")
        logger.info("fastlane would need sudo rights to update itself, however, running 'sudo' is not recommended.")
        logger.info("If you still want to use this action, please read the documentation how to set this up:")
        logger.info("https://docs.fastlane.tools/actions/#update_fastlane")
        return
      end

      highest_versions = updater.highest_installed_gems.keep_if { |key| tools_to_update.include?(key) }
      update_needed = updater.which_to_update(highest_versions, tools_to_update)

      if update_needed.count == 0
        logger.info("Nothing to update for fastlane.ci")
        return
      end

      # suppress updater output - very noisy
      unless ENV["FASTLANE_CI_VERBOSE"]
        Gem::DefaultUserInteraction.ui = Gem::SilentUI.new
      end

      update_needed.each do |tool_info|
        tool = tool_info[0]
        local_version = Gem::Version.new(highest_versions[tool].version)

        # Approximate_recommendation will create a string like "~> 0.10" from a
        # version 0.10.0, e.g. one that is valid for versions >= 0.10 and <1.0
        requirement_version = local_version.approximate_recommendation
        updater.update_gem(tool, Gem::Requirement.new(requirement_version))

        logger.info("Finished updating #{tool}")
      end

      logger.info("Cleaning up old versions...")
      cleaner.options[:args] = tools_to_update
      cleaner.execute

      logger.info("fastlane.ci successfully updated! I will now restart myself... 😴")

      # Set no_update to true so we don't try to update again
      # TODO: Use actual fastlane.ci launch command
      # exec("FL_NO_UPDATE=true #{$PROGRAM_NAME} #{ARGV.join(' ')}")
    end
  end
end
