require "sinatra/reloader"

require_relative "logging_module"

module FastlaneCI
  # TODO: This doesn't work just yet
  # This mixin allows automatic resource reloading
  # call enable_resource_reloading with the file path with an optional block to be executed after reload
  module ResourceReloader
    include FastlaneCI::Logging

    def enable_resource_reloading(file_path: nil)
      logger.debug("Enabling resource reloading for: #{file_path}")
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
