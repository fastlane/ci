require_relative "data_sources/json_user_data_source"
require_relative "../shared/models/github_provider_credential"
require_relative "../shared/logging_module"

module FastlaneCI
  # Provides access to user stuff
  class UserService
    include FastlaneCI::Logging
    attr_accessor :user_data_source

    def initialize(user_data_source: nil)
      unless user_data_source.nil?
        raise "user_data_source must be descendant of #{UserDataSource.name}" unless user_data_source.class <= UserDataSource
      end

      if user_data_source.nil?
        # Default to JSONUserDataSource
        logger.debug("user_data_source is new, using `ENV[\"data_store_folder\"]` if available, or `sample_data` folder")
        data_store_folder = ENV["data_store_folder"] # you can set it at runtime!
        data_store_folder ||= File.join(FastlaneCI::FastlaneApp.settings.root, "sample_data")
        user_data_source = JSONUserDataSource.new(json_folder_path: data_store_folder)
      end

      self.user_data_source = user_data_source
    end

    def create_user!(email: nil, password: nil)
      email = email.strip

      unless self.user_data_source.user_exist?(email: email)
        logger.debug("creating account #{email}")
        provider_credential = GitHubProviderCredential.new(email: email)
        return self.user_data_source.create_user!(email: email, password: password, provider_credential: provider_credential)
      end

      logger.debug("account #{email} already exists!")
      return nil
    end

    def update_user!(user: nil)
      self.user_data_source.update_user!(user: user)
    end

    def login(email: nil, password: nil, ci_config_repo: nil)
      email = email.strip

      logger.debug("attempting to login user with email #{email}")
      user = self.user_data_source.login(email: email, password: password)
      return user
    end
  end
end
