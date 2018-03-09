require "fastlane"

module FastlaneCI
  # Implementation for the FastlaneCore::Interface abstract class
  # this is set to the fastlane runner before executing the user's Fastfile
  class FastlaneCIOutput < FastlaneCore::Interface
    # the file path to the log file for the output
    attr_accessor :file_path

    # The block that's being called for each new line
    # that should be printed out to the user
    attr_accessor :each_line_block

    def initialize(file_path: nil, each_line_block: nil)
      raise "No file path provided" if file_path.to_s.length == 0
      raise "No each_line_block provided" if each_line_block.nil?
      self.file_path = file_path
      self.each_line_block = each_line_block
    end

    def log
      return @log if @log

      @log ||= Logger.new(self.file_path)

      @log.formatter = proc do |severity, datetime, progname, msg|
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
      self.each_line_block.call(
        type: :error,
        message: message,
        time: Time.now
      )
    end

    def important(message)
      log.warn(message.to_s.yellow)
      self.each_line_block.call(
        type: :important,
        message: message,
        time: Time.now
      )
    end

    def success(message)
      log.info(message.to_s.green)
      self.each_line_block.call(
        type: :success,
        message: message,
        time: Time.now
      )
    end

    # If you're here because you saw the exception: `wrong number of arguments (given 0, expected 1)`
    # that means you're accidentally calling this method instead of a local variable on the stack frame before this
    def message(message)
      log.info(message.to_s)
      self.each_line_block.call(
        type: :message,
        message: message,
        time: Time.now
      )
    end

    def deprecated(message)
      log.error(message.to_s.deprecated)
      self.each_line_block.call(
        type: :error,
        message: message,
        time: Time.now
      )
    end

    def command(message)
      log.info("$ #{message}".cyan)
      self.each_line_block.call(
        type: :command,
        message: message,
        time: Time.now
      )
    end

    def command_output(message)
      actual = (message.split("\r").last || "") # as clearing the line will remove the `>` and the time stamp
      actual.split("\n").each do |msg|
        prefix = msg.include?("▸") ? "" : "▸ "
        self.each_line_block.call(
          type: :command_output,
          message: prefix + msg,
          time: Time.now
        )
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

      self.each_line_block.call(
        type: :header,
        message: message,
        time: Time.now
      )
    end

    # TODO: Check if we can find a good way to not have to
    #   overwrite all these methods
    def crash!(exception)
      self.each_line_block.call(
        type: :crash,
        message: exception.to_s,
        time: Time.now
      )
      raise FastlaneCrash.new, exception.to_s
    end

    def user_error!(error_message, options = {})
      self.each_line_block.call(
        type: :user_error,
        message: error_message,
        time: Time.now
      )
      super(error_message, options)
    end

    def shell_error!(error_message, options = {})
      self.each_line_block.call(
        type: :shell_error,
        message: error_message,
        time: Time.now
      )
      super(error_message, options)
    end

    def build_failure!(error_message, options = {})
      self.each_line_block.call(
        type: :build_failure,
        message: error_message,
        time: Time.now
      )
      super(error_message, options)
    end

    def test_failure!(error_message)
      self.each_line_block.call(
        type: :test_failure,
        message: error_message,
        time: Time.now
      )
      super(error_message)
    end

    def abort_with_message!(error_message)
      self.each_line_block.call(
        type: :abort,
        message: error_message,
        time: Time.now
      )
      super(error_message)
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
      self.crash!("Could not retrieve response as fastlane runs fastlane.ci and can't ask for additional inputs during its run")
    end
  end
end
