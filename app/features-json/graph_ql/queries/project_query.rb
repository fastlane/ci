require_relative "../types/project_type"

module FastlaneCI
  module Query
    Projects = GraphQL::ObjectType.define do
      name "Projects"
      field :projects, types[Types::ProjectType] do
        argument(:id, types.String)
        description "Get a list of Projects"
        resolve lambda do |_obj, args, _ctx|
          if !args[:id].nil?
            return FastlaneCI::Services.project_service.project_by_id(args[:id])
          else
            return FastlaneCI::Services.project_service.projects
          end
        end
      end
    end
  end
end
