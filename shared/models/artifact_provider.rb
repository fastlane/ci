module FastlaneCI
  # Abstract class that provides the interface to load and store Artifacts.
  class ArtifactProvider
    # :class_name should always be the class name of the child class which inherits from ArtifactProvider.
    # This attribute is key in order to be able to persist the information enough and recreate it on later executions.
    # @return [String] The class of the provider
    attr_accessor :class_name

    # The store! method must implement the utility in order to store some
    # temporary Artifact into a resource storage, such as disk, Cloud Storage, etc.
    #
    # @param [Artifact] artifact, the artifact we want to store.
    # @param [Build] build, the build which generated the artifact.
    # @param [Project] project, the project which generated the build.
    # @return [Artifact] the resulting Artifact after being stored by the ArtifactProvider.
    def store!(artifact: nil, build: nil, project: nil)
      not_implemented(__method__)
    end

    # The retrieve! method must implement the utility in order to fetch the information
    # and provide it in a way that it may be accessed by the user. Typically, this reference
    # will always be a String.
    #
    # @param [Artifact] artifact, the artifact we want to retrieve.
    # @return [String] the resulting Artifact reference after being retrieved by the ArtifactProvider.
    def retrieve!(artifact: nil)
      not_implemented(__method__)
    end
  end
end
