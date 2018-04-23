require_relative "data_sources/json_environment_data_source"
require_relative "../shared/logging_module"
require_relative "./services"

module FastlaneCI
  # Provides access to environment variables
  class UserService
    include FastlaneCI::Logging
    attr_accessor :environment_data_source

    def initialize(environment_data_source: nil)
      unless environment_data_source.nil?
        unless environment_data_source.class <= EnvironmentDataSource
          raise "environment_data_source must be descendant of #{EnvironmentDataSource.name}"
        end
      end

      if environment_data_source.nil?
        # Default to JSONEnvironmentDataSource
        # TODO: do we need `sample_data` here?
        logger.debug(
          "environment_data_source is new, using `ENV[\"data_store_folder\"]` if available, or `sample_data` folder"
        )
        data_store_folder = ENV["data_store_folder"] # you can set it at runtime!
        data_store_folder ||= File.join(FastlaneCI::FastlaneApp.settings.root, "sample_data")
        environment_data_source = JSONEnvironmentDataSource.create(json_folder_path: data_store_folder)
      end

      self.environment_data_source = environment_data_source
    end

    #####################################################
    # @!group Users Logic
    #####################################################

    def environment_variables
      require 'pry'; binding.pry
      environment_data_source.environment_variables
    end

    def create_user!(id: nil, email: nil, password: nil)
      email = email.strip

      unless user_data_source.user_exist?(email: email)
        logger.debug("Creating account #{email}")
        return user_data_source.create_user!(id: id, email: email, password: password, provider_credentials: [])
      end

      logger.debug("Account #{email} already exists!")
      return nil
    end

    # TODO: THIS ALWAYS TURNS THE PROVIDER CREDENTIALS INTO HASHES
    def update_user!(user: nil)
      success = user_data_source.update_user!(user: user)
      if success
        # TODO: remove this message if https://github.com/fastlane/ci/issues/292 is fixed
        # rubocop:disable Metrics/LineLength
        logger.info("Updated user #{user.email}, that means you should call `find_user(id:)` see https://github.com/fastlane/ci/issues/292")
        # rubocop:enable Metrics/LineLength
      end
      return success
    end

    def delete_user!(user: nil)
      user_data_source.delete_user!(user: user)
    end

    # @return [User]
    def find_user(id: nil)
      return user_data_source.find_user(id: id)
    end

    def login(email:, password:)
      email = email.strip

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

    protected

    # Not sure if this must be here or not, but we can open a discussion on this.
    def commit_repo_changes!(message: nil, file_to_commit: nil)
      Services.configuration_git_repo.commit_changes!(commit_message: message, file_to_commit: file_to_commit)
    end
  end
end
