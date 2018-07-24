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

    def setup_repo(git_url, git_sha)
      dir = Dir.mktmpdir("fastlane-ci")
      logger.debug("Changing into working directory #{dir}.")

      # TODO: need Git Credentials for private repos.
      Dir.mkdir(File.join(dir, "repo"))
      Dir.chdir(File.join(dir, "repo"))

      # We only want to fetch a single sha. This is how we can do that:
      sh("git init .")
      sh("git remote add origin #{git_url}")
      sh("git fetch --depth=1 origin #{git_sha}")
      sh("git checkout FETCH_HEAD")

      sh("bundle install --deployment")
    end

    def run_fastlane(command)
      command_string = "#{command.bin} #{command.parameters.join(' ')}"
      logger.debug("invoking #{command_string}")
      sh(command_string, env: command.env.to_h)

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
      artifact_archive_path = File.join(
        File.expand_path("..", artifact_path), "Archive.tgz"
      )
      logger.debug("Archiving directory #{artifact_path} to #{artifact_archive_path}")

      Dir.chdir(artifact_path) do
        sh("tar -cvzf #{artifact_archive_path} .")
      end

      return artifact_archive_path
    end

    ##
    # use this to execute shell commands so the output can be streamed back as a response.
    #
    # this command will either execute successfully or raise an exception.
    def sh(*params, env: {})
      ##
      # ensure our command is executed without the config of fastlane.ci
      Bundler.with_clean_env do
        @output_queue.push(params.join(" "))
        stdin, stdouterr, thread = Open3.popen2e(env, *params)
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
end
