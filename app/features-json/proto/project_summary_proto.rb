require_relative "../../shared/models/project"

module FastlaneCI
  # Proto to expose the basic info about a project.
  class ProjectSummaryProto
    class << self
      def object_class
        FastlaneCI::Project
      end

      def proto_from(object:)
        raise "Incorrect object type. Expected #{self.object_class}, got #{object.class}" unless object.kind_of?(self.object_class)
        return object.to_object_dictionary(ignore_instance_variables: object.instance_variables - self.attributes)
      end

      def attributes
        return [:@id, :@project_name]
      end
    end
  end
end
