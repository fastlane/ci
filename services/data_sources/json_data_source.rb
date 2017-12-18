require_relative "data_source"

module FastlaneCI
  class JSONDataSource < DataSource
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
