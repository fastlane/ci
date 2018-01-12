require "sinatra/reloader"

require_relative "logging_module"

module FastlaneCI
  # This doesn't work just yet
  module ResourceReloader
    include FastlaneCI::Logging

    def enable_resource_reloading(file_path: nil)
      logger.debug("enabling resource reloading for: #{file_path}")
      self.class.configure(:development) do |configuration|
        self.class.register(Sinatra::Reloader)
        configuration.also_reload(file_path)
        configuration.after_reload do
          yield
        end
      end
    end
  end
end
