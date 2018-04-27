module FastlaneCI
  # Data source for global environment variables for fastlane.ci
  class EnvironmentDataSource
    def environment_variables
      not_implemented(__method__)
    end

    def update_environment_variable!(variable: nil)
      not_implemented(__method__)
    end

    def delete_environment_variable!(variable: nil)
      not_implemented(__method__)
    end

    def create_environment_variable!(key: nil, value: nil)
      not_implemented(__method__)
    end
  end
end
