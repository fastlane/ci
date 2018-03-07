require_relative "../shared/logging_module"

module FastlaneCI
  # super class for all fastlane.ci workers
  # Subclass this class, and implement `work` and `interval_time`
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
          self.scheduler.schedule do
            self.work
            # If we're running in debug mode, don't run these things continuously
            if ENV["FASTLANE_CI_THREAD_DEBUG_MODE"]
              logger.debug("stopping worker after this work unit")
              self.die!
            end
          end
        rescue StandardError => ex
          logger.error("[#{self.class} Exception]: #{ex}: ")
          logger.error(ex.backtrace.join("\n"))
          logger.error("[#{self.class}] Killing thread #{self.thread_id} due to exception\n")
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
