require_relative "logging_module"

module FastlaneCI
  # Find your Fastfile easier!
  class FastfileFinder
    class << self
      include FastlaneCI::Logging
    end

    def self.find_fastfile_in_repo(repo:, relative_path: false)
      local_storage = repo.local_folder
      return self.search_path(path: local_storage, relative_path: relative_path)
    end

    # if you're using this with the fastfile parser, you need to use `relative: false`
    def self.search_path(path:, relative_path: false)
      # First assume the fastlane directory and its file is in the root of the project
      fastfiles = Dir[File.join(path, "fastlane/Fastfile")]
      # If not, it might be in a subfolder
      fastfiles = Dir[File.join(path, "**/fastlane/Fastfile")] if fastfiles.count == 0

      if fastfiles.count > 1
        logger.error("Ugh, multiple Fastfiles found, we're gonna have to build a selection in the future")
        # for now, just take the first one
      end

      if fastfiles.count == 0
        logger.error("No Fastfile found at #{path}/fastlane/Fastfile, or any descendants")
      else
        fastfile_path = fastfiles.first
        if relative_path
          fastfile_path = Pathname.new(fastfile_path).relative_path_from(Pathname.new(path))
        end
      end
      return fastfile_path
    end
  end
end
