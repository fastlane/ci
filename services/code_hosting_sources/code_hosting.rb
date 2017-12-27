module FastlaneCI
  # Abstract base class for all code hosting data sources
  class CodeHosting
    def session_valid?
      not_implemented(__method__)
    end
  end
end
