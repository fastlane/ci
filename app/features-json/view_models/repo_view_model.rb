require_relative "../../shared/json_convertible"

module FastlaneCI
  # View model to expose the basic info about repositories.
  class RepoViewModel
    include FastlaneCI::JSONConvertible

    # @return [String]
    attr_reader :full_name

    # @return [String]
    attr_reader :url

    def initialize(repo:)
      @full_name = repo.full_name
      @url = repo.url
    end
  end
end
