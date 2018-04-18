Dir[File.join(__dir__, "queries", "*.rb")].each { |file| require file }

require "graphql"

# Load FastlaneCISchema as a global.
module FastlaneCI
  # Wrapper class for the GraphQL schema of the application.
  class GraphQLSchema
    def self.schema
      @schema ||= GraphQL::Schema.define do
        query Query.Projects
      end
    end
  end
end
