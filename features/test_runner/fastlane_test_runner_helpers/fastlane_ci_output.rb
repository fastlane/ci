module FastlaneCI
  # Implementation for the FastlaneCore::Interface abstract class
  # this is set to the fastlane runner before executing the user's Fastfile
  class FastlaneCIOutput < FastlaneCore::Interface
    # TODO: replace the implementation of all methods below
    require "tty-screen"

    def log
      return @log if @log

      $stdout.sync = true

      @log ||= Logger.new($stdout)

      @log.formatter = proc do |severity, datetime, progname, msg|
        "#{format_string(datetime, severity)}#{msg}\n"
      end

      @log
    end

    def format_string(datetime = Time.now, severity = "")
      "[fastlane.ci] [#{datetime.strftime('%H:%M:%S')}]: "
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

    def message(message)
      log.info(message.to_s)
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
      # log.debug(message.to_s) if FastlaneCore::Globals.verbose?
    end

    def header(message)
      format = format_string
      if message.length + 8 < TTY::Screen.width - format.length
        message = "--- #{message} ---"
        i = message.length
      else
        i = TTY::Screen.width - format.length
      end
      success("-" * i)
      success(message)
      success("-" * i)
    end

    #####################################################
    # @!group Errors: Inputs
    #####################################################

    def interactive?
      interactive = true
      interactive = false if $stdout.isatty == false
      # interactive = false if Helper.ci?
      return interactive
    end

    def input(message)
      verify_interactive!(message)
      ask("#{format_string}#{message.to_s.yellow}").to_s.strip
    end

    def confirm(message)
      verify_interactive!(message)
      agree("#{format_string}#{message.to_s.yellow} (y/n)", true)
    end

    def select(message, options)
      verify_interactive!(message)

      important(message)
      choose(*options)
    end

    def password(message)
      verify_interactive!(message)

      ask("#{format_string}#{message.to_s.yellow}") { |q| q.echo = "*" }
    end

    private

    def verify_interactive!(message)
      return if interactive?
      important(message)
      crash!("Could not retrieve response as fastlane runs in non-interactive mode")
    end
  end
end
