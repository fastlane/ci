require_relative "worker_base"
require_relative "worker_scheduler"

module FastlaneCI
  # Responsible for running `git pull` on the ci config repo
  # in the background, every x seconds
  class RefreshConfigDataSourcesWorker < WorkerBase
    def work
      FastlaneCI::Services.project_service.refresh_repo
    end

    def scheduler
      WorkerScheduler.new(sleep_interval: 15)
    end
  end
end
