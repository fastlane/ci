require "rufus-scheduler"

module FastlaneCI
  # Class that handles the scheduling for fastlane.ci workers
  class WorkerScheduler
    include FastlaneCI::Logging

    # Sleep in seconds
    attr_reader :interval_time

    # Ex. '5 0 * * *' do something every day, five minutes after midnight
    # (see "man 5 crontab" in your terminal)
    # This uses the local time zone
    attr_reader :cron_schedule

    attr_reader :scheduler

    def initialize(interval_time: nil, cron_schedule: nil)
      @interval_time = interval_time
      @cron_schedule = cron_schedule
      @scheduler = Rufus::Scheduler.new

      if interval_time.nil? && cron_schedule.nil?
        raise "Either a cron_schedule or a interval_time is mandatory."
      end

      if !interval_time.nil? && !cron_schedule.nil?
        raise "Only one of cron_schedule or a interval_time is allowed."
      end
    end

    def schedule(&block)
      if interval_time
        scheduler.every(interval_time) { block.call }
      elsif cron_schedule
        job_id = scheduler.cron(cron_schedule) { block.call }
        scheduled_cron_job = scheduler.job(job_id)
        logger.debug("Scheduling cron job for #{cron_schedule}.")
        time_from_now = (scheduled_cron_job.next_time - Time.now) / (60 * 60)
        logger.debug("Next time #{scheduled_cron_job.next_time} or #{time_from_now} hours from now.")
      end
    end

    # Shuts down the scheduler, ceases any scheduler/triggering activity.
    def shutdown
      scheduler.shutdown if scheduler
    end
  end
end
