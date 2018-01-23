require_relative "data_sources/user_data_source"
require_relative "../shared/models/github_provider_credential"
require_relative "../shared/logging_module"

module FastlaneCI
  # Provides access to user stuff
  class UserService
    include FastlaneCI::Logging
    attr_accessor :data_source

    def initialize(data_source: nil)
      if data_source.nil?
        logger.debug("data_source is new, using `ENV[\"data_store_folder\"]` if available, or `sample_data` folder")
        data_store_folder = ENV["data_store_folder"] # you can set it at runtime!
        data_store_folder ||= File.join(FastlaneCI::FastlaneApp.settings.root, "sample_data")
        data_source = UserDataSource.new(json_folder_path: data_store_folder)
      end

      self.data_source = data_source
    end

    def create_user!(email: nil, password: nil)
      email = email.strip

      unless self.data_source.user_exist?(email: email)
        logger.debug("creating account #{email}")
        provider_credential = GitHubProviderCredential.new(email: email)
        return self.data_source.create_user!(email: email, password: password, provider_credential: provider_credential)
      end

      logger.debug("account #{email} already exists!")
      return nil
    end

    def update_user!(user: nil)
      self.data_source.update_user!(user: user)
    end

    def login(email: nil, password: nil)
      email = email.strip

      logger.debug("attempting to login user with email #{email}")
      user = self.data_source.login(email: email, password: password)
      return user
    end
  end
end
