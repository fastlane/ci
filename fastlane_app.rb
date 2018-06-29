# External
require "sinatra/base"
require "fastfile_parser"
require "git"

# Internal
require_relative "app/version"
require_relative "app/shared/fastlane_ci_error" # has to be required before other files
require_relative "app/services/services"
require_relative "app/workers/refresh_config_data_sources_worker"
require_relative "app/workers/check_for_fastlane_ci_update_worker"
require_relative "app/shared/logging_module"
require_relative "app/shared/dot_keys_variables"
require_relative "app/features/build_runner/build_runner"

# All things fastlane ci related go in this module
module FastlaneCI
  # Used to use the same layout file across all views
  # https://stackoverflow.com/questions/26080599/sinatra-method-to-set-layout
  def self.default_layout
    return "../../../features/global/layout".to_sym
  end

  # Reference to the `DotKeysVariables` object that holds all the values from the
  # .keys file. This does not include the global or project specific environment variables
  def self.dot_keys
    @_dot_keys ||= FastlaneCI::DotKeysVariables.new
    return @_dot_keys
  end

  def self.server_version
    return @server_version
  end

  local_fastlane_ci_checkout_path = __dir__
  begin
    ci_repo = Git.open(local_fastlane_ci_checkout_path)
    @server_version = ci_repo.log.first
  rescue StandardError => ex
    @server_version = "unknown server version, #{ex.message}"
  end

  # Our CI app main class
  class FastlaneApp < Sinatra::Base
    include FastlaneCI::Logging
    Thread.current[:thread_id] = "main"

    # Switch from the default Sinatra web server to `thin`
    # which is required to support web socket streams for the
    # display of real-time output
    set(:server, "thin")
    get "/favicon.ico" do
      send_file(File.join(File.dirname(__FILE__), "public", "favicon.ico"))
    end

    if ENV["FASTLANE_CI_ERB_CLIENT"]
      get "/" do
        if session[:user]
          redirect("/dashboard_erb")
        else
          redirect("/login_erb")
        end
      end
    else
      # Any route that hasn't already been defined
      get "/*" do
        # Using __FILE__ as root to search relative to this file
        send_file(File.join(File.dirname(__FILE__), "public", ".dist", "index.html"))
      end
    end
  end
end
