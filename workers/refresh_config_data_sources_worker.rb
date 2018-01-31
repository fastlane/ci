require_relative "worker_base"

module FastlaneCI
  # Responsible for running `git pull` on the ci config repo
  # in the background, every x seconds
  class RefreshConfigDataSourcesWorker < WorkerBase
    def work
      FastlaneCI::FastlaneApp::PROJECT_DATA_SOURCE.refresh_repo
    end

    def timeout
      15
    end
  end
end
