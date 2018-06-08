require_relative "./file_writers/keys_writer"
require_relative "./services"
require_relative "../shared/dot_keys_variables"

module FastlaneCI
  # Logic pertaining to .keys environment variable configuration, this only includes the .keys file
  class DotKeysVariableService
    # Write .keys configuration file with proper environment variables. Don't
    # override old environment variables with `nil` values
    #
    # @param  [Hash] locals
    def write_keys_file!(
      locals: {
        ci_base_url: nil,
        encryption_key: nil,
        ci_user_password: nil,
        ci_user_api_token: nil,
        repo_url: nil,
        initial_onboarding_user_api_token: nil
      }
    )
      non_nil_new_env_variables = locals.reject { |_k, v| v.nil? }
                                        .each_with_object({}) { |(k, v), hash| hash[k.to_sym] = v }
      new_dot_key_variables = FastlaneCI.dot_keys.all.merge(non_nil_new_env_variables)
      KeysWriter.new(path: keys_file_path, locals: new_dot_key_variables).write!
      reload_dot_env!
    end

    def keys
      return DotKeysVariables.new
    end

    # Reloads the dot key variables and resets the memoized services that
    # depend on their values
    def reload_dot_env!
      return unless File.exist?(keys_file_path)

      require "dotenv"
      ENV.update(Dotenv::Environment.new(keys_file_path, true))

      Services.reset_services!
    end

    # Verifies the proper environment variables needed to run the server are
    # present
    #
    # @return [Boolean]
    def all_dot_variables_non_nil?
      return FastlaneCI.dot_keys.all.none? { |_k, v| v.nil? || v.empty? }
    end

    # The path to the environment variables file
    #
    # @return [String]
    def keys_file_path
      return File.join(Dir.home, keys_file_path_from_home)
    end

    # The path to the environment variables file relative to HOME
    #
    # @return [String]
    def keys_file_path_relative_to_home
      return "~/#{keys_file_path_from_home}"
    end

    private

    # The path to the environment variables file having in mind
    # that it's relative to HOME
    #
    # @return [String]
    def keys_file_path_from_home
      return ".fastlane/ci/.keys"
    end
  end
end
