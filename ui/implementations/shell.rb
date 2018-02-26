# coding: utf-8

require "colored"
require "highline/import"
require "logger"
require "tty-prompt"
require "tty-screen"

module FastlaneCI
  # Shell UI helper methods
  class Shell
    # Configures the UI logger. Disables output when tests are running and the
    # 'DEBUG' flag has not been passed
    #
    # @return [Logger]
    def log
      return @log if @log

      $stdout.sync = true

      @log ||= begin
        if ENV["RACK_ENV"] == "test" && !ENV["DEBUG"]
          $stdout.puts("Logging disabled while running tests. Force them by setting the DEBUG environment variable")
          Logger.new(nil)
        else
          Logger.new($stdout)
        end
      end

      @log.formatter = proc do |severity, datetime, progname, msg|
        "#{format_string(datetime, severity)}#{msg}\n"
      end

      @log
    end

    def format_string(datetime = Time.now, severity = "")
      return "[#{datetime.strftime('%H:%M:%S')}]: "
    end

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
      # as clearing the line will remove the `>` and the time stamp
      actual = (message.split("\r").last || "")
      actual.split("\n").each do |msg|
        prefix = msg.include?("▸") ? "" : "▸ "
        log.info(prefix + "" + msg.magenta)
      end
    end

    def verbose(message)
      log.debug(message.to_s) if ENV["FASTLANE_CI_VERBOSE"]
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

    def interactive?
      interactive = true
      interactive = false if $stdout.isatty == false
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

    private

    def verify_interactive!(message)
      return if interactive?
      important(message)
      raise Error("Could not retrieve response as fastlane runs in non-interactive mode")
    end
  end
end
