require_relative "./fastlane_log"
require "fastlane"

module FastlaneCI
  # Implementation for the FastlaneCore::Interface abstract class
  # this is set to the fastlane runner before executing the user's Fastfile
  class FastlaneCIOutput < FastlaneCore::Interface
    # The block being called for each new line that should
    # be stored in the log.
    attr_reader :each_line_block

    attr_accessor :output_listeners

    def initialize(each_line_block: nil)
      raise "No each_line_block provided" if each_line_block.nil?
      @each_line_block = each_line_block
      self.output_listeners = []
    end

    def add_output_listener!(listener)
      unless listener.kind_of?(FastlaneLog)
        raise "Invalid listener provider, expected #{FastlaneLog.class.name} got #{listener.class.name}"
      end
      output_listeners << listener
    end

    #####################################################
    # @!group Messaging: show text to the user
    #####################################################

    def error(message)
      output_listeners.each { |listener| listener.error(message) }
      each_line_block.call(
        type: :error,
        message: message,
        time: Time.now
      )
    end

    def important(message)
      output_listeners.each { |listener| listener.important(message) }
      each_line_block.call(
        type: :important,
        message: message,
        time: Time.now
      )
    end

    def success(message)
      output_listeners.each { |listener| listener.success(message) }
      each_line_block.call(
        type: :success,
        message: message,
        time: Time.now
      )
    end

    # If you're here because you saw the exception: `wrong number of arguments (given 0, expected 1)`
    # that means you're accidentally calling this method instead of a local variable on the stack frame before this
    def message(message)
      output_listeners.each { |listener| listener.message(message) }
      each_line_block.call(
        type: :message,
        message: message,
        time: Time.now
      )
    end

    def deprecated(message)
      output_listeners.each { |listener| listener.deprecated(message) }
      each_line_block.call(
        type: :error,
        message: message,
        time: Time.now
      )
    end

    def command(message)
      output_listeners.each { |listener| listener.command(message) }
      each_line_block.call(
        type: :command,
        message: message,
        time: Time.now
      )
    end

    def command_output(message)
      actual = (message.split("\r").last || "") # as clearing the line will remove the `>` and the time stamp
      actual.split("\n").each do |msg|
        prefix = msg.include?("▸") ? "" : "▸ "
        resulting_message = prefix + msg

        output_listeners.each { |listener| listener.message(resulting_message) }
        each_line_block.call(
          type: :command_output,
          message: resulting_message,
          time: Time.now
        )
      end
    end

    def verbose(message)
      output_listeners.each { |listener| listener.verbose(message) }
    end

    def header(message)
      output_listeners.each { |listener| listener.header(message) }
      each_line_block.call(
        type: :header,
        message: message,
        time: Time.now
      )
    end

    def crash!(exception)
      raise FastlaneCrash.new, exception.to_s
    end

    def user_error!(error_message, options = {})
      super(error_message, options)
    end

    def shell_error!(error_message, options = {})
      super(error_message, options)
    end

    def build_failure!(error_message, options = {})
      super(error_message, options)
    end

    def test_failure!(error_message)
      super(error_message)
    end

    def abort_with_message!(error_message)
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
