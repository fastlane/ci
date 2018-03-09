require_relative "./file_writers/keys_writer"
require_relative "./services"

module FastlaneCI
  # Logic pertaining to environment variable configuration
  class EnvironmentVariableService
    # Write .keys configuration file with proper environment variables
    #
    # @param  [Hash] locals
    def write_keys_file!(
      locals: {
        encryption_key: nil,
        ci_user_email: nil,
        ci_user_password: nil,
        repo_url: nil,
        clone_user_email: nil,
        clone_user_api_token: nil
      }
    )
      KeysWriter.new(path: keys_file_path, locals: locals).write!
    end

    # Reloads the environment variables and resets the memoized services that
    # depend on their values
    def reload_dot_env!
      return unless File.exist?(keys_file_path)

      require "dotenv"
      ENV.update(Dotenv::Environment.new(keys_file_path))

      Services.reset_services!
    end

    # Verifies the proper environment variables needed to run the server are
    # present
    def verify_env_variables
      if FastlaneCI.env.encryption_key.nil?
        warn("Error: unable to decrypt sensitive data without environment variable `FASTLANE_CI_ENCRYPTION_KEY` set")
        exit(1)
      end

      if FastlaneCI.env.ci_user_email.nil? || FastlaneCI.env.ci_user_password.nil?
        warn("Error: ensure you have your `FASTLANE_CI_USER` and `FASTLANE_CI_PASSWORD`environment variables set")
        exit(1)
      end

      if FastlaneCI.env.repo_url.nil?
        warn("Error: ensure you have your `FASTLANE_CI_REPO_URL` environment variable set")
        exit(1)
      end
    end

    # The path to the environment variables file
    #
    # @return [String]
    def keys_file_path
      File.join(Dir.home, ".fastlane/ci/.keys")
    end
  end
end
