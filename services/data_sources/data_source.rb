module FastlaneCI
  # Abstract base class for all data sources
  class DataSource
    def load_builds(max: 10)
      not_implemented(__method__)
    end
  end
end
