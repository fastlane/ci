require "tmpdir"
require_relative "../agent"

module FastlaneCI::Agent
  ##
  # stateless invocation recipes go here
  module Recipes
    include Logging

    ##
    # set up a Queue that is used to push output from stdout/err from commands that shell out.
    def output_queue=(value)
      @output_queue = value
    end

    def setup_repo(git_url)
      dir = Dir.mktmpdir("fastlane-ci")
      Dir.chdir(dir)
      logger.debug("Changing into working directory #{dir}.")

      sh("git clone --depth 1 #{git_url} repo")

      Dir.chdir("repo")
      sh("gem install bundler --no-doc")
      sh("bundle install --deployment")

      sh("gem install cocoapods --no-doc")
      sh("pod install")
    end

    def run_fastlane(command)
      command_string = "#{command.bin} #{command.parameters.join(" ")}"
      logger.debug("invoking #{command_string}")
      # TODO: send the env to fastlane.
      sh(command_string)

      true
    end

    ##
    # archive a directory using tar/gz
    #
    # @return String path to the archive that was created or nil if there was an error.
    def archive_artifacts(artifact_path)
      unless Dir.exist?(artifact_path)
        logger.debug("No artifacts found in #{File.expand_path(artifact_path)}.")
        return
      end
      logger.debug("Archiving directory #{artifact_path}")

      Dir.chdir(artifact_path) do
        sh("tar -cvzf Archive.tgz .")
      end

      return File.join(artifact_path, "Archive.tgz")
    end

    ##
    # use this to execute shell commands so the output can be streamed back as a response.
    #
    # this command will either execute successfully or raise an exception.
    def sh(*params, env: {})
      @output_queue.push(params.join(" "))
      stdin, stdouterr, thread = Open3.popen2e(*params)
      stdin.close

      # `gets` on a pipe will block until the pipe is closed, then returns nil.
      while (line = stdouterr.gets)
        logger.debug(line)
        @output_queue.push(line)
      end

      exit_status = thread.value.exitstatus
      if exit_status != 0
        raise SystemCallError.new(line, exit_status)
      end
    end
  end
end
