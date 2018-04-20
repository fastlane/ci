require_relative "logging_module"

module FastlaneCI
  # Find your Fastfile easier!
  class FastfileFinder
    class << self
      include FastlaneCI::Logging
    end

    def self.find_fastfile_in_repo(repo:, relative_path: false)
      local_storage = repo.local_folder
      return search_path(path: local_storage, relative_path: relative_path)
    end

    # if you're using this with the fastfile parser, you need to use `relative: false`
    def self.search_path(path:, relative_path: false)
      # fetch recursively for a Fastfile
      fastfiles = Dir.glob(File.join(path, "**/Fastfile"), File::FNM_CASEFOLD)

      if fastfiles.count == 0
        directory_contents = Dir[File.expand_path(path)].join("\n")
        logger.error("No Fastfile found at #{path}/fastlane/Fastfile, or any descendants")
        logger.error("Directory contents: #{directory_contents}")
        return nil
      end

      if fastfiles.count > 1
        logger.error("Ugh, multiple Fastfiles found, we're gonna have to build a selection in the future")
        # for now, just take the first one
      end

      # return the Fastfile at path/fastlane/Fastfile if present, otherwise the first one found
      fastfile_path = FastfileFinder.find_prioritary_fastfile_path(paths: fastfiles, path: path)
      if relative_path
        fastfile_path = Pathname.new(fastfile_path).relative_path_from(Pathname.new(path))
      end
      return fastfile_path
    end

    def self.find_prioritary_fastfile_path(paths:, path: nil)
      path = path.nil? ? "" : "#{path}/".downcase
      paths = paths.select { |current| current.downcase.end_with?("/fastfile") || current.casecmp("fastfile").zero? }
      return paths
             .find { |current| current.downcase == "#{path}fastlane/fastfile" } || paths.first
    end
  end
end
