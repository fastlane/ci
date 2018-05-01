require "faraday"
require_relative "worker_base"
require_relative "worker_scheduler"
require_relative "../shared/logging_module"

module FastlaneCI
  # Responsible for checking for new fastlane.ci updates on
  # GitHub/RubyGems
  class CheckForFastlaneCIUpdateWorker < WorkerBase
    include FastlaneCI::Logging

    attr_reader :scheduler

    def initialize
      @scheduler = WorkerScheduler.new(interval_time: 60 * 60)

      # This starts the work by calling `work`
      super
    end

    def check_for_update
      logger.debug("checking for updates for fastlane.ci...")
      return unless update_available?

      logger.info("fastlane.ci version #{version_of_latest_release} is available")
      # TODO: in a separate PR I'm gonna add support for automatically updating itself
      #       right now we're just printing out that there is an update available
      #       the plan is to have the actual updater in a separate class so that it can be
      #       triggered from various locations, including UI for the user
    end

    def update_available?
      return version_of_latest_release > currently_running_version
    end

    def work
      check_for_update
    rescue StandardError => ex
      logger.error(ex)
    end

    private

    def url
      # This will be replaced with the RubyGems URL once fastlane.ci is live
      return "https://api.github.com/repos/fastlane/ci/releases"
    end

    def version_of_latest_release
      # This will be replaced with RubyGems specific parsing once the release is live
      releases = JSON.parse(Faraday.get(url).body)
      return Gem::Version.new(releases.first["tag_name"])
    end

    def currently_running_version
      return Gem::Version.new(FastlaneCI::VERSION)
    end
  end
end
