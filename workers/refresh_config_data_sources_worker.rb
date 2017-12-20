require_relative "worker_base"

module FastlaneCI
  class RefreshConfigDataSourcesWorker < WorkerBase
    def work
      FastlaneCI::FastlaneApp::CONFIG_DATA_SOURCE.setup_repo
    end

    def timeout
      15
    end
  end
end
