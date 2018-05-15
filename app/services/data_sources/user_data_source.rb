module FastlaneCI
  # Data source for all things related to users
  class UserDataSource
    # returns all users from the system
    def users
      not_implemented(__method__)
    end

    # returns logged-in user if password check passes, else nil
    def login(email:, password:)
      not_implemented(__method__)
    end

    # If user exists, returns true, else false
    def user_exist?(email:)
      not_implemented(__method__)
    end

    # Saves the updated user state or raises exception
    def update_user!(user:)
      not_implemented(__method__)
    end

    # Deletes the user
    def delete_user!(user:)
      not_implemented(__method__)
    end

    # Creates and returns a user if one doesn't already exist, otherwise fails and returns nil
    def create_user!(id: nil, email:, password:, provider_credentials: [])
      not_implemented(__method__)
    end

    # @return [User]
    def find_user(id:)
      not_implemented(__method__)
    end
  end
end
