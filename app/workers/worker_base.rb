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

    def busy?
      @mutex.synchronize do
        return @busy
      end
    end

    def busy=(busy)
      @mutex.synchronize do
        @busy = busy
      end
    end

    def initialize
      @mutex = Mutex.new
      @busy = false
      # TODO: do we need a thread here to do the work or does `scheduler.schedule` handle that?
      @thread = Thread.new do
        begin
          # We have the `work` inside a `begin rescue`
          # so that if something fails, the thread still is alive
          scheduler.schedule do
            begin
              # This can cause an exception, in production mode, we don't re-raise the exception
              # in development mode, we re-raise so we can catch it and understand how to handle it
              if busy?
                logger.debug("#{thread_id} is still busy, skipping a scheduled run")
              else
                work
              end
              # If we're running in debug mode, don't run these things continuously
              if ENV["FASTLANE_CI_THREAD_DEBUG_MODE"]
                logger.debug("Stopping worker after this work unit")
                die!
              end
            rescue StandardError => ex
              logger.error("[#{self.class} Exception], work unit caused exception: #{ex}: ")
              logger.error(ex.backtrace.join("\n"))
              if Thread.abort_on_exception == true
                logger.error("[#{self.class}] Thread.abort_on_exception is `true`, killing task re-raising exception")
                die!
                raise ex
              end
            end
          end
        rescue StandardError => ex
          logger.error("Worker scheduler had a problem")
          logger.error(ex.backtrace.join("\n"))
          if Thread.abort_on_exception == true
            logger.error("[#{self.class}] Thread.abort_on_exception is `true`, killing task and re-raising exception")
            die!
            raise ex
          end
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
      logger.debug("Shutting down worker's scheduler")
      scheduler.shutdown
    end

    def scheduler
      not_implemented(__method__)
    end
  end
end
