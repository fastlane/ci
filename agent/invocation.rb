require_relative "agent"
require_relative "invocation/recipes"
require_relative "invocation/state_machine"

module FastlaneCI::Agent
  ##
  # the Invocation models a fastlane invocation.
  # It has states and state transitions
  # streams update to state, logs, and artifacts via the `yielder`
  #
  #
  #
  class Invocation
    include Logging
    include Recipes
    prepend StateMachine

    def initialize(invocation_request, yielder)
      @invocation_request = invocation_request
      @yielder = yielder
      @output_queue = Queue.new
      self.output_queue = @output_queue
    end

    ##
    # StateMachine actions
    # These methods run as hooks whenever a transition was successful.
    ##

    def run
      # send logs that get put on the output queue.
      # this needs to be on a separate thread since Queue is a threadsafe blocking queue.
      Thread.new do
        while state == "running"
          # pop is blocking, hence we need another check for the state.
          log_line = @output_queue.pop
          send_log(log_line) if state == "running"
        end
      end

      git_url = command_env(:GIT_URL)
      git_sha = command_env(:GIT_SHA)

      setup_repo(git_url, git_sha)

      @artifact_path = File.expand_path("artifacts")
      FileUtils.mkdir_p(@artifact_path)

      # TODO: set this properly for the fastlane invocation
      ENV["FASTLANE_CI_ARTIFACTS"] = @artifact_path

      # TODO: ensure we are able to satisfy the request
      # unless has_required_xcode_version?
      #   reject(RuntimeError.new("Does not have required xcode version!. This is hardcode to be random."))
      #   return
      # end

      if run_fastlane(@invocation_request.command)
        finish
      else
        # fail is a keyword, so we must call self.
        # rubocop:disable Style/RedundantSelf
        self.fail
        # rubocop:enable Style/RedundantSelf
      end
    end

    def finish
      file_path = archive_artifacts(@artifact_path)
      send_file(file_path)
      succeed
    end

    # the `succeed` method has no special action
    # the StateMachine requires it's implemented as it's called after a successful transition
    def succeed
      # no-op
    end

    # the `fail` method has no special action
    # the StateMachine requires it's implemented as it's called after a successful transition
    def fail
      # no-op
    end

    def throw(exception)
      logger.error("Caught Error: #{exception.inspect}")

      error = FastlaneCI::Proto::InvocationResponse::Error.new
      error.description = exception.message
      error.stacktrace = exception.backtrace.join("\n")
      error.exit_status = exception.errno if exception.respond_to?(:errno)

      @yielder << FastlaneCI::Proto::InvocationResponse.new(error: error)
    end

    def reject(exception)
      logger.info("Invocation rejected: #{exception}")

      error = FastlaneCI::Proto::InvocationResponse::Error.new
      error.description = exception.message

      @yielder << FastlaneCI::Proto::InvocationResponse.new(error: error)
    end

    ## state machine transition guards

    def has_required_xcode_version?
      # TODO: bring in from build_runner
      rand(10) > 3 # 1 in 3 chance of failure
    end

    # responder methods

    def send_state(event, _payload)
      logger.debug("State changed. Event `#{event}` => #{state}")

      @yielder << FastlaneCI::Proto::InvocationResponse.new(state: state.to_s.upcase.to_sym)
    end

    ##
    # TODO: parse the line, using parse_log_line to figure out the severity and timestamp
    def send_log(line, level = :DEBUG)
      log = FastlaneCI::Proto::Log.new(message: line, timestamp: Time.now.to_i, level: level)
      @yielder << FastlaneCI::Proto::InvocationResponse.new(log: log)
    end

    def send_file(file_path, chunk_size: 1024 * 1024)
      unless File.exist?(file_path)
        logger.warn("No file found at #{file_path}. Skipping sending the file.")
        return
      end

      file = File.open(file_path, "rb")

      until file.eof?
        artifact = FastlaneCI::Proto::InvocationResponse::Artifact.new
        artifact.chunk = file.read(chunk_size)
        artifact.filename = File.basename(file_path)

        @yielder << FastlaneCI::Proto::InvocationResponse.new(artifact: artifact)
      end
    end

    private

    def command_env(key)
      key = key.to_s
      env = @invocation_request.command.env.to_h
      if env.key?(key)
        env[key]
      else
        raise NameError, "`#{env}` does not have a key `#{key}`"
      end
    end

    def parse_log_line(line)
      re = /^[A-Z], \[([0-9:T\.-]+) #(\d+)\] (\w+) -- (\w*?): (.*)$/
      if (match_data = re.match(line))
        return match_data.captures
      end
    end
  end
end
