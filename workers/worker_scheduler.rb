require "rufus-scheduler"

module FastlaneCI
  # Class that handles the scheduling for fastlane.ci workers
  class WorkerScheduler
    # Sleep in seconds
    attr_accessor :sleep_interval
    # Ex. '5 0 * * *' do something every day, five minutes after midnight
    # (see "man 5 crontab" in your terminal)
    attr_accessor :cron_time
    attr_accessor :scheduler

    def initialize(sleep_interval: nil, cron_time: nil)
      self.sleep_interval = sleep_interval
      self.cron_time = cron_time
      self.scheduler = Rufus::Scheduler.new

      if self.sleep_interval.nil? && self.cron_time.nil?
        raise "Either a cron_time or a sleep_interval is mandatory."
      end
    end

    def schedule(&block)
      if !self.sleep_interval.nil?
        block.call
        Kernel.sleep(self.sleep_interval)
      elsif !self.cron_time.nil?
        self.scheduler.cron(self.cron_time) { block.call }
      end
    end
  end
end
