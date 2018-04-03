require_relative "../shared/authenticated_controller_base"
require_relative "./proto/project_summary_proto"

module FastlaneCI
  # Controller for providing all data relating to projects
  class ProjectJSONController < AuthenticatedControllerBase
    HOME = "/data/projects"

    get HOME do
      current_provider_credential = check_and_get_provider_credential
      current_user_config_service = self.current_user_config_service
      all_projects = current_user_config_service.projects(provider_credential: current_provider_credential)
      all_projects_proto = all_projects.map do |project|
        ProjectSummaryProto.proto_from(object: project)
      end

      return all_projects_proto.to_json
    end
  end
end
