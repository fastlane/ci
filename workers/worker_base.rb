require_relative "../shared/logging_module"

module FastlaneCI
  # super class for all fastlane.ci workers
  # Subclass this class, and implement `work` and `sleep_interval`
  class WorkerBase
    include FastlaneCI::Logging

    attr_accessor :worker_id

    def thread_id=(new_value)
      @thread[:thread_id] = new_value
    end

    def thread_id
      return @thread[:thread_id]
    end

    def initialize
      @thread = Thread.new do
        begin
          # We have the `work` inside a `begin rescue`
          # so that if something fails, the thread still is alive
          self.scheduler.schedule { self.work }
        rescue StandardError => ex
          puts("[#{self.class} Exception]: #{ex}: ")
          puts(ex.backtrace.join("\n"))
          puts("[#{self.class}] Killing thread #{self.thread_id} due to exception\n")
          self.die!
        end
      end
    end

    def work
      not_implemented(__method__)
    end

    def provider_type
      not_implemented(__method__)
    end

    def die!
      logger.debug("Stopping worker")
      self.scheduler.shutdown
    end

    def scheduler
      not_implemented(__method__)
    end
  end
end
