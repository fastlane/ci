module FastlaneCI
  # Abstract base class for all config data sources
  class ProjectDataSource
    def projects
      not_implemented(__method__)
    end

    def refresh_repo
      not_implemented(__method__)
    end

    def create_project!(
      name: nil,
      repo_config: nil,
      enabled: nil,
      platform: nil,
      lane: nil,
      artifact_provider: nil,
      job_triggers: nil
    )
      not_implemented(__method__)
    end

    def update_project!(project: nil)
      not_implemented(__method__)
    end

    def delete_project!(project: nil)
      not_implemented(__method__)
    end
  end
end
