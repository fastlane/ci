require_relative "./json_authenticated_controller_base"
require_relative "./view_models/artifact_view_model"

module FastlaneCI
  # Controller for providing all data relating to artifacts
  class ArtifactJSONController < JSONAuthenticatedControllerBase
    HOME = "/data/project/:project_id/build/:build_number/artifact"

    class ArtifactNotFoundError < FastlaneCIError
    end

    # Fetch all the available metadata for a given artifact, the return data is JSON
    get "#{HOME}/:artifact_id/info" do |project_id, build_number, artifact_id|
      begin
        artifact, = fetch_artifact_details(
          project_id: project_id,
          build_number: build_number,
          artifact_id: artifact_id
        )
        return ArtifactViewModel.new(artifact: artifact).to_json
      rescue ArtifactNotFoundError
        return { error: "Couldn't find artifact" }.to_json
      end
    end

    # Download the given artifact, the return data could be anything
    # If the artifact isn't available, you'll get an error message via the JSON format
    get "#{HOME}/:artifact_id/download" do |project_id, build_number, artifact_id|
      begin
        _, artifact_reference, uri = fetch_artifact_details(
          project_id: project_id,
          build_number: build_number,
          artifact_id: artifact_id
        )

        if uri.scheme.nil?
          unless File.exist?(artifact_reference)
            return { error: "Couldn't find artifact" }.to_json
          end

          if File.directory?(artifact_reference)
            # TODO: we probably never ever want to store directories as artifacts anyway
            return { error: "Artifact is a directory", details: artifact_reference }.to_json
          end

          send_file(artifact_reference, filename: artifact_reference, type: "Application/octet-stream")
        else
          return {
            url: artifact_reference
          }.to_json
        end
      rescue ArtifactNotFoundError
        return { error: "Couldn't find artifact" }.to_json
      end
    end

    private

    def fetch_artifact_details(project_id:, build_number:, artifact_id:)
      project = user_project_with_id(project_id: project_id)
      build = project.builds.find { |b| b.number == build_number.to_i }

      artifact = build.artifacts.find { |find_artifact| find_artifact.id == artifact_id }

      raise ArtifactNotFoundError if artifact.nil?

      begin
        artifact_reference = artifact.provider.retrieve!(artifact: artifact)
        raise ArtifactNotFoundError if artifact_reference.nil?
      rescue StandardError
        raise ArtifactNotFoundError
      end

      uri = URI.parse(artifact_reference)

      return artifact, artifact_reference, uri
    end
  end
end
