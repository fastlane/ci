require "bcrypt"
require_relative "../../shared/logging_module"
require_relative "../../shared/json_convertible"
require_relative "../../shared/models/user"
require_relative "../../shared/models/provider"
require_relative "../../shared/models/github_provider"

module FastlaneCI
  # Mixin the JSONConvertible class for User
  class User
    include FastlaneCI::JSONConvertible
  end

  # Mixin the JSONConvertible class for all Providers
  class Provider
    include FastlaneCI::JSONConvertible
  end

  # Data source for all things related to users
  class UserDataSource
    include FastlaneCI::Logging

    attr_accessor :json_folder_path

    class << self
      attr_accessor :file_semaphore
    end

    # can't have us reading and writing to a file at the same time, now can we?
    UserDataSource.file_semaphore = Mutex.new

    def initialize(json_folder_path: nil)
      logger.debug("Using folder path for data: #{json_folder_path}")
      @json_folder_path = json_folder_path
      # load up the json file here
      # parse all data into objects so we can fail fast on error
      reload_users
    end

    def user_file_path(path: "users.json")
      File.join(self.json_folder_path, path)
    end

    def users
      UserDataSource.file_semaphore.synchronize do
        return @users
      end
    end

    def reload_users
      UserDataSource.file_semaphore.synchronize do
        unless File.exist?(user_file_path)
          @users = []
          return
        end

        @users = JSON.parse(File.read(user_file_path)).map do |user_object_hash|
          user = User.from_json!(user_object_hash)
          user.providers = load_providers_from_provider_hash_array(provider_array: user.providers)
          user
        end
      end
    end

    # TODO: this could be automatic
    def load_providers_from_provider_hash_array(provider_array: nil)
      return provider_array.map do |provider_hash|
        type = provider_hash["@type"]

        # currently only supports 1 type, but we could automate this part too
        if type == FastlaneCI::Provider::PROVIDER_TYPES[:github]
          GitHubProvider.from_json!(provider_hash)
        end
      end
    end

    def login(email: nil, password: nil)
      user = self.users.select { |existing_user| existing_user.email.casecmp(email.downcase).zero? }.first

      # user doesn't exist
      return nil if user.nil?

      # cool, the user exists, but we need to check the password
      user_password = BCrypt::Password.new(user.password_hash)

      # sweet, it matches, return the user
      if user_password == password
        logger.debug("user #{email} authenticated")
        return user
      end

      # nope, wrong password
      return nil
    end

    # just check to see if we have a user with that email...
    def user_exist?(email: nil)
      user = self.users.select { |existing_user| existing_user.email.casecmp(email.downcase).zero? }.first
      if user.nil?
        return false
      else
        return true
      end
    end

    def create_user!(email: nil, password: nil, provider: nil)
      password_hash = BCrypt::Password.create(password)
      new_user = User.new(email: email, password_hash: password_hash, providers: [provider])
      UserDataSource.file_semaphore.synchronize do
        existing_user = @users.select { |user| user.email.casecmp(email.downcase).zero? }.first
        if existing_user.nil?
          @users << new_user

          logger.debug("Added user #{new_user.email}, writing out users.json to #{user_file_path}")
          File.write(user_file_path, JSON.pretty_generate(@users.map(&:to_object_dictionary)))
          return new_user
        else
          logger.debug("Couldn't add user #{new_user.email} because they already exist")
          return nil
        end
      end
    end
  end
end
