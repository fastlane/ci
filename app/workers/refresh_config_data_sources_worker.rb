require_relative "worker_base"
require_relative "worker_scheduler"

module FastlaneCI
  # Responsible for running `git pull` on the ci config repo
  # in the background, every x seconds
  class RefreshConfigDataSourcesWorker < WorkerBase
    attr_reader :scheduler

    def initialize
      @scheduler = WorkerScheduler.new(interval_time: 15)
    end

    def work
      FastlaneCI::Services.project_service.refresh_repo
    end
  end
end
