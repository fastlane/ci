module FastlaneCI
  class WorkerBase
    def initialize
      Thread.new do
        loop do
          sleep(self.timeout)
          self.work
        end
      end
    end

    def work
      not_implemented(__method__)
    end

    # Timeout in seconds
    def timeout
      not_implemented(__method__)
    end
  end
end
