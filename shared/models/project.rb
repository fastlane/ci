require "securerandom"

module FastlaneCI
  # All metadata about a project.
  # A project is usually a git url, a lane, and a project name, like "Production Build"
  class Project
    # @return [GitRepoConfig] URL to the Git repo
    attr_accessor :repo_config

    # @return [String] Name of the project
    attr_accessor :project_name

    # @return [String] lane name to run
    attr_accessor :lane

    # @return [Boolean]
    attr_accessor :enabled

    # @return [String] Is a UDID so we're not open to ID guessing attacks
    attr_accessor :id

    def initialize(repo_config: nil, enabled: nil, project_name: nil, lane: nil, id: nil)
      self.repo_config = repo_config
      self.enabled = enabled
      self.project_name = project_name
      self.id = id || SecureRandom.uuid
      self.lane = lane
    end

    def builds
      # TODO: I assume we have to move this somewhere else?
      # TODO: Services::BUILD_SERVICE doesn't work as the file isn't included
      # TODO: ugh, I'm doing something wrong, I think?
      #
      # TODO: Yup, don't call .builds here, use build_server and pass a project in to an api like: builds(project: project)
      json_folder_path = FastlaneCI::Service.project_data_source.git_repo.git_config.local_repo_path
      build_service = FastlaneCI::BuildService.new(data_source: BuildDataSource.new(json_folder_path: json_folder_path))
      builds = build_service.list_builds(project: self)

      return builds.sort_by(&:number).reverse
    end
  end
end
