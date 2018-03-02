require "rufus-scheduler"

module FastlaneCI
  # Class that handles the scheduling for fastlane.ci workers
  class WorkerScheduler
    include FastlaneCI::Logging

    # Sleep in seconds
    attr_accessor :sleep_interval
    # Ex. '5 0 * * *' do something every day, five minutes after midnight
    # (see "man 5 crontab" in your terminal)
    # This uses the local time zone
    attr_accessor :cron_schedule
    attr_accessor :scheduler

    def initialize(sleep_interval: nil, cron_schedule: nil)
      self.sleep_interval = sleep_interval
      self.cron_schedule = cron_schedule
      self.scheduler = Rufus::Scheduler.new

      if self.sleep_interval.nil? && self.cron_schedule.nil?
        raise "Either a cron_schedule or a sleep_interval is mandatory."
      end

      if !self.sleep_interval.nil? && !self.cron_schedule.nil?
        raise "Only one of cron_schedule or a sleep_interval is allowed."
      end
    end

    def schedule(&block)
      if self.sleep_interval
        self.scheduler.every(self.sleep_interval) { block.call }
      elsif self.cron_schedule
        job_id = self.scheduler.cron(self.cron_schedule) { block.call }
        scheduled_cron_job = self.scheduler.job(job_id)
        logger.debug("Scheduling cron job for #{self.cron_schedule}.")
        logger.debug("Next time #{scheduled_cron_job.next_time} or #{(scheduled_cron_job.next_time - Time.now) / (60 * 60)} hours from now.")
      end
    end

    # Shuts down the scheduler, ceases any scheduler/triggering activity.
    def shutdown
      self.scheduler.shutdown if self.scheduler
    end
  end
end
