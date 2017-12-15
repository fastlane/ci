require_relative "data_source"

module FastlaneCI
  class JSONDataSource < DataSource
    def load_builds(max: 10)
      yield(%w[build1 build2], "paging_token")
    end
  end
end
