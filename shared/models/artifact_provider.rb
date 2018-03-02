module FastlaneCI
  # Abstract class that provides the interface to load and store Artifacts.
  class ArtifactProvider

    # @return [String] The class of the provider
    attr_accessor :class_name

    def store!(artifact: nil, build: nil, project: nil)
      not_implemented(__method__)
    end

    def retrieve!(artifact: nil, build: nil, project: nil)
      not_implemented(__method__)
    end
  end
end
