module FastlaneCI
  # Implementation for the FastlaneCore::Interface abstract class
  # this is set to the fastlane runner before executing the user's Fastfile
  class FastlaneCIOutput < FastlaneCore::Interface
    # the file path to the log file for the output
    attr_accessor :file_path

    # The block that's being called for each new line
    # that should be printed out to the user
    attr_accessor :block

    def initialize(file_path: nil, block: nil)
      raise "No file path provided" if file_path.to_s.length == 0
      raise "No block provided" if block.nil?
      self.file_path = file_path
      self.block = block
    end

    def log
      return @log if @log

      @log ||= Logger.new(self.file_path)

      @log.formatter = proc do |severity, datetime, progname, msg|
        # This is the only way I found
        # to run code for each line
        self.block.call(msg)

        "#{format_string(datetime, severity)}#{msg}\n"
      end

      @log
    end

    def format_string(datetime = Time.now, severity = "")
      "[#{datetime.strftime('%H:%M:%S')}]: "
    end

    #####################################################
    # @!group Messaging: show text to the user
    #####################################################

    def error(message)
      log.error(message.to_s.red)
      self.block.call(
        type: :error,
        message: message
      )
    end

    def important(message)
      log.warn(message.to_s.yellow)
    end

    def success(message)
      log.info(message.to_s.green)
    end

    def message(message)
      log.info(message.to_s)
      self.block.call(
        type: :error,
        message: message
      )
      # TODO: stopped here, migrate the other methods also
    end

    def deprecated(message)
      log.error(message.to_s.deprecated)
    end

    def command(message)
      log.info("$ #{message}".cyan)
    end

    def command_output(message)
      actual = (message.split("\r").last || "") # as clearing the line will remove the `>` and the time stamp
      actual.split("\n").each do |msg|
        prefix = msg.include?("▸") ? "" : "▸ "
        log.info(prefix + "" + msg.magenta)
      end
    end

    def verbose(message)
      # TODO: are we gonna have a verbose mode?
      # Proposal: we can log into 2 files, one the normal output
      #     and one with the verbose output
      # log.debug(message.to_s) if FastlaneCore::Globals.verbose?
    end

    def header(message)
      message = "--- #{message} ---"
      i = message.length
      success("-" * i)
      success(message)
      success("-" * i)
    end

    #####################################################
    # @!group Errors: Inputs
    #####################################################

    def interactive?
      # fastlane.ci is non-interactive
      return false
    end

    def input(message)
      non_interactive!(message)
    end

    def confirm(message)
      non_interactive!(message)
    end

    def select(message, options)
      non_interactive!(message)
    end

    def password(message)
      non_interactive!(message)
    end

    private

    def non_interactive!(message)
      important(message)
      crash!("Could not retrieve response as fastlane runs fastlane.ci and can't ask for additional inputs during its run")
    end
  end
end
