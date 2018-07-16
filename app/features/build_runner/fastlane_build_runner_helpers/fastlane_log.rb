require "fastlane"

module FastlaneCI
  # Implementation for the FastlaneCore::Interface abstract class
  # this is set to the fastlane runner before executing the user's Fastfile
  class FastlaneLog
    # The file path for the log output.
    attr_reader :file_path

    # Base severity from which the log will store events.
    attr_reader :severity

    def initialize(file_path: nil, severity: Logger::INFO)
      raise "No file path provided" if file_path.to_s.length == 0
      @file_path = file_path
      @severity = severity
    end

    def log
      return @log if @log

      @log ||= Logger.new(file_path)

      @log.formatter = proc do |log_severity, datetime, progname, msg|
        "#{format_string(datetime, log_severity)}#{msg}\n"
      end

      @log.sev_threshold = severity

      return @log
    end

    def format_string(datetime = Time.now, severity = "")
      return "[#{datetime.strftime('%H:%M:%S')}]: "
    end

    #####################################################
    # @!group Messaging: show text to the user
    #####################################################

    def error(message)
      log.error(message.to_s.red)
    end

    def important(message)
      log.warn(message.to_s.yellow)
    end

    def success(message)
      log.info(message.to_s.green)
    end

    # If you're here because you saw the exception: `wrong number of arguments (given 0, expected 1)`
    # that means you're accidentally calling this method instead of a local variable on the stack frame before this
    def message(message)
      log.info(message.to_s)
    end

    def deprecated(message)
      log.error(message.to_s.deprecated)
    end

    def command(message)
      log.info("$ #{message}".cyan)
    end

    def verbose(message)
      log.debug(message.to_s)
    end

    def header(message)
      message = "--- #{message} ---"
      i = message.length
      success("-" * i)
      success(message)
      success("-" * i)
    end
  end
end
