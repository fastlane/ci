module FastlaneCI
  # Data source for global environment variables for fastlane.ci
  class EnvironmentDataSource
    # returns all users from the system
    def all_variables
      not_implemented(__method__)
    end

    # Saves the updated environment variable or raises exception
    def update_variable!(variable: nil)
      not_implemented(__method__)
    end

    # Deletes a given environment variable
    def delete_variable!(variable: nil)
      not_implemented(__method__)
    end

    # Creates and returns an environment variable if one doesn't already exist, otherwise fails and returns nil
    def create_variable!(key: nil, value: nil)
      not_implemented(__method__)
    end
  end
end
