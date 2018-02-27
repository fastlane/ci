require "rufus-scheduler"

module FastlaneCI
  # Class that handles the scheduling for fastlane.ci workers
  class WorkerScheduler
    # Sleep in seconds
    attr_accessor :sleep_interval
    # Ex. '5 0 * * *' do something every day, five minutes after midnight
    # (see "man 5 crontab" in your terminal)
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
      if !self.sleep_interval.nil?
        block.call
        Kernel.sleep(self.sleep_interval)
      elsif !self.cron_schedule.nil?
        self.scheduler.cron(self.cron_schedule) { block.call }
      end
    end
  end
end
