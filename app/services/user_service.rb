require_relative "data_sources/json_user_data_source"
require_relative "../shared/models/github_provider_credential"
require_relative "../shared/logging_module"
require_relative "./services"

module FastlaneCI
  # Provides access to user stuff
  class UserService
    include FastlaneCI::Logging
    attr_accessor :user_data_source

    def initialize(user_data_source: nil)
      unless user_data_source.nil?
        unless user_data_source.class <= UserDataSource
          raise "user_data_source must be descendant of #{UserDataSource.name}"
        end
      end

      if user_data_source.nil?
        # Default to JSONUserDataSource
        logger.debug(
          "user_data_source is new, using `ENV[\"data_store_folder\"]` if available, or `sample_data` folder"
        )
        data_store_folder = ENV["data_store_folder"] # you can set it at runtime!
        data_store_folder ||= File.join(FastlaneCI::FastlaneApp.settings.root, "sample_data")
        user_data_source = JSONUserDataSource.create(data_store_folder)
      end

      self.user_data_source = user_data_source
    end

    #####################################################
    # @!group Users Logic
    #####################################################

    def users
      user_data_source.users
    end

    def create_user!(id: nil, email:, password:)
      email.strip!

      unless user_data_source.user_exist?(email: email)
        logger.debug("Creating account #{email}")
        return user_data_source.create_user!(id: id, email: email, password: password, provider_credentials: [])
      end

      logger.debug("Account #{email} already exists!")
      return nil
    end

    def update_user!(user:)
      user_data_source.update_user!(user: user)
    end

    def delete_user!(user:)
      user_data_source.delete_user!(user: user)
    end

    # @return [User]
    def find_user(id:)
      return user_data_source.find_user(id: id)
    end

    def login(email:, password:)
      email.strip!

      logger.debug("Attempting to login user with email #{email}")
      user = user_data_source.login(email: email, password: password)
      return user
    end

    #####################################################
    # @!group Provider Credential Logic
    #####################################################

    # Creates a new provider credential, and adds it to the User's provider
    # credentials array
    def create_provider_credential!(user_id: nil, id: nil, email: nil, api_token: nil, full_name: nil)
      provider_credential = GitHubProviderCredential.new(
        id: id, email: email, api_token: api_token, full_name: full_name
      )
      user = find_user(id: user_id)

      if user.nil?
        logger.error("Can't create provider credential for user, since user does not exist.")
      else
        user.provider_credentials << provider_credential
        update_user!(user: user)
      end
    end

    # Look-up the user by `user_id` and updates the provider credential
    # associated with the provider credential `id`
    def update_provider_credential!(user_id: nil, id: nil, email: nil, api_token: nil, full_name: nil)
      provider_credential = GitHubProviderCredential.new(email: email, api_token: api_token, full_name: full_name)
      user = find_user(id: user_id)

      if user.nil?
        logger.error("Can't update provider credential for user, since user does not exist.")
      else
        # Delete the old credential, and push on the new one
        new_provider_credentials = user.provider_credentials
                                       .delete_if { |credential| credential.id == id }
                                       .push(provider_credential)

        new_user = User.new(
          id: user.id,
          email: user.email,
          password_hash: user.password_hash,
          provider_credentials: new_provider_credentials
        )
        update_user!(user: new_user)
      end
    end
  end
end
