require_relative "./fastlane_log"
require "fastlane"

module FastlaneCI
  # Implementation for the FastlaneCore::Interface abstract class
  # this is set to the fastlane runner before executing the user's Fastfile
  class FastlaneCIOutput < FastlaneCore::Interface
    # The block being called for each new line that should
    # be stored in the log.
    attr_reader :each_line_block

    def initialize(each_line_block: nil)
      raise "No each_line_block provided" if each_line_block.nil?
      @each_line_block = each_line_block
      @output_listeners = []
    end

    def add_output_listener!(listener)
      raise "Invalid listener provider, expected #{FastlaneLog.class.name} got #{listener.class.name}" \
        unless listener.kind_of?(FastlaneLog)
      @output_listeners << listener
    end

    #####################################################
    # @!group Messaging: show text to the user
    #####################################################

    def error(message)
      @output_listeners.each { |listener| listener.error(message) }
      each_line_block.call(
        type: :error,
        message: message,
        time: Time.now
      )
    end

    def important(message)
      @output_listeners.each { |listener| listener.important(message) }
      each_line_block.call(
        type: :important,
        message: message,
        time: Time.now
      )
    end

    def success(message)
      @output_listeners.each { |listener| listener.success(message) }
      each_line_block.call(
        type: :success,
        message: message,
        time: Time.now
      )
    end

    # If you're here because you saw the exception: `wrong number of arguments (given 0, expected 1)`
    # that means you're accidentally calling this method instead of a local variable on the stack frame before this
    def message(message)
      @output_listeners.each { |listener| listener.message(message) }
      each_line_block.call(
        type: :message,
        message: message,
        time: Time.now
      )
    end

    def deprecated(message)
      @output_listeners.each { |listener| listener.deprecated(message) }
      each_line_block.call(
        type: :error,
        message: message,
        time: Time.now
      )
    end

    def command(message)
      @output_listeners.each { |listener| listener.command(message) }
      each_line_block.call(
        type: :command,
        message: message,
        time: Time.now
      )
    end

    def command_output(message)
      @output_listeners.each { |listener| listener.command_outupt(message) }
      actual = (message.split("\r").last || "") # as clearing the line will remove the `>` and the time stamp
      actual.split("\n").each do |msg|
        prefix = msg.include?("▸") ? "" : "▸ "
        each_line_block.call(
          type: :command_output,
          message: prefix + msg,
          time: Time.now
        )
      end
    end

    def verbose(message)
      @output_listeners.each { |listener| listener.verbose(message) }
    end

    def header(message)
      @output_listeners.each { |listener| listener.header(message) }
      each_line_block.call(
        type: :header,
        message: message,
        time: Time.now
      )
    end

    # TODO: Check if we can find a good way to not have to
    #   overwrite all these methods
    def crash!(exception)
      each_line_block.call(
        type: :crash,
        message: exception.to_s,
        time: Time.now
      )
      raise FastlaneCrash.new, exception.to_s
    end

    def user_error!(error_message, options = {})
      each_line_block.call(
        type: :user_error,
        message: error_message,
        time: Time.now
      )
      super(error_message, options)
    end

    def shell_error!(error_message, options = {})
      each_line_block.call(
        type: :shell_error,
        message: error_message,
        time: Time.now
      )
      super(error_message, options)
    end

    def build_failure!(error_message, options = {})
      each_line_block.call(
        type: :build_failure,
        message: error_message,
        time: Time.now
      )
      super(error_message, options)
    end

    def test_failure!(error_message)
      each_line_block.call(
        type: :test_failure,
        message: error_message,
        time: Time.now
      )
      super(error_message)
    end

    def abort_with_message!(error_message)
      each_line_block.call(
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
      crash!("Can't ask for additional inputs during fastlane run when in CI")
    end
  end
end
