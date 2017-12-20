module FastlaneCI
  # Abstract base class for all config data sources
  class ConfigDataSource
    def repos
      not_implemented(__method__)
    end
  end
end
