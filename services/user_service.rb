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
        # TODO: From @KrauseFx: I don't understand those defaults, do we want to keep them?
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

    def login(email: nil, password: nil, ci_config_repo: nil)
      email = email.strip

      logger.debug("attempting to login user with email #{email}")
      user = self.data_source.login(email: email, password: password)
      if user.nil?
        user = trigger_initial_ci_setup(email: email, password: password, ci_config_repo: ci_config_repo)
      end
      return user
    end

    def trigger_initial_ci_setup(email: nil, password: nil, ci_config_repo: nil)
      logger.info("No config repo cloned yet, doing that now")

      # This happens on the first launch of CI
      # We don't have access to the config directory yet
      # So we'll use ENV variables that are used for the initial clone only
      #
      # Long term, we'll have a nice onboarding flow, where you can enter those credentials
      # as part of a web UI. But for containers (e.g. Google Cloud App Engine)
      # we'll have to support ENV variables also, for the initial clone, so that's the code below
      # Clone the repo, and login the user
      provider_credential = GitHubProviderCredential.new(email: ENV["FASTLANE_CI_INITIAL_CLONE_EMAIL"],
                                                       api_token: ENV["FASTLANE_CI_INITIAL_CLONE_API_TOKEN"])
      FastlaneCI::GitConfigDataSource.new(git_repo_config: ci_config_repo, provider_credential: provider_credential)
      self.data_source = UserDataSource.new(json_folder_path: ci_config_repo.local_repo_path)

      logger.debug("attempting to login user with email #{email}")
      return self.data_source.login(email: email, password: password)
    rescue => ex
      logger.error("Something went wrong on the initial clone")
      logger.error("Make sure to provide your `FASTLANE_CI_INITIAL_CLONE_EMAIL` and `FASTLANE_CI_INITIAL_CLONE_API_TOKEN` ENV variables")
      raise ex
    end
  end
end
