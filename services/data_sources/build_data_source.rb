module FastlaneCI
  # Data source for all things related to builds
  class BuildDataSource
    def initialize
      # load up the json file here
      # parse all data into objects so we can fail fast on error
    end

    def load_builds(max: 10)
      print("reminder: max value: #{max} is currently unused")

      # return builds from json
      yield(%w[build1 build2], "paging_token")
    end
  end
end
