require_relative "./view_models/artifact_view_model"

module FastlaneCI
  # Controller for providing all data relating to artifacts
  class ArtifactJSONController < APIController
    HOME = "/data/project/:project_id/build/:build_number/artifact"

    class ArtifactNotFoundError < FastlaneCIError
    end

    # Fetch all the available metadata for a given artifact, the return data is JSON
    # This will include a download URL
    get "#{HOME}/:artifact_id" do |project_id, build_number, artifact_id|
      begin
        artifact, uri = fetch_artifact_details(
          project_id: project_id,
          build_number: build_number,
          artifact_id: artifact_id
        )
        return ArtifactViewModel.new(artifact: artifact, uri: uri).to_json
      rescue ArtifactNotFoundError
        json_error!(
          error_message: "Couldn't find artifact",
          error_key: "Artifact.Missing",
          error_code: 404
        )
      end
    end

    # Download the given artifact, the return data could be anything
    # If the artifact isn't available, you'll get an error message via the JSON format
    #
    # TODO: The code below should work, in case we decide to provide a `download` feature
    #
    # get "#{HOME}/:artifact_id/download" do |project_id, build_number, artifact_id|
    #   begin
    #     _, artifact_reference, uri = fetch_artifact_details(
    #       project_id: project_id,
    #       build_number: build_number,
    #       artifact_id: artifact_id
    #     )
    #     if uri.scheme.nil?
    #       unless File.exist?(artifact_reference)
    #         return { error: "Couldn't find artifact" }.to_json
    #       end
    #       if File.directory?(artifact_reference)
    #         # TODO: we probably never ever want to store directories as artifacts anyway
    #         return { error: "Artifact is a directory", details: artifact_reference }.to_json
    #       end
    #       send_file(artifact_reference, filename: artifact_reference, type: "Application/octet-stream")
    #     else
    #       return {
    #         url: artifact_reference
    #       }.to_json
    #     end
    #   rescue ArtifactNotFoundError
    #     return { error: "Couldn't find artifact" }.to_json
    #   end
    # end

    private

    def fetch_artifact_details(project_id:, build_number:, artifact_id:)
      project = current_project
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

    def current_project
      current_project = FastlaneCI::Services.project_service.project_by_id(params[:project_id])
      unless current_project
        json_error!(
          error_message: "Can't find project with ID #{params[:project_id]}",
          error_key: "Project.Missing",
          error_code: 404
        )
      end

      return current_project
    end
  end
end
