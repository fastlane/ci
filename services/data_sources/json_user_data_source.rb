require "bcrypt"
require "securerandom"
require_relative "json_data_source"
require_relative "user_data_source"
require_relative "../../shared/logging_module"
require_relative "../../shared/json_convertible"
require_relative "../../shared/models/user"
require_relative "../../shared/models/provider_credential"
require_relative "../../shared/models/github_provider_credential"

module FastlaneCI
  # Mixin the JSONConvertible class for User
  class User
    include FastlaneCI::JSONConvertible
  end

  # Mixin the JSONConvertible class for all Providers
  class ProviderCredential
    include FastlaneCI::JSONConvertible
  end

  # Data source for users backed by JSON
  class JSONUserDataSource < UserDataSource
    include FastlaneCI::JSONDataSource
    include FastlaneCI::Logging

    class << self
      attr_accessor :file_semaphore
    end

    # can't have us reading and writing to a file at the same time
    JSONUserDataSource.file_semaphore = Mutex.new

    def after_creation(**params)
      logger.debug("Using folder path for user data: #{json_folder_path}")
      # load up the json file here
      # parse all data into objects so we can fail fast on error
      self.reload_users
    end

    def user_file_path(path: "users.json")
      File.join(self.json_folder_path, path)
    end

    def users
      JSONUserDataSource.file_semaphore.synchronize do
        return @users
      end
    end

    def reload_users
      JSONUserDataSource.file_semaphore.synchronize do
        unless File.exist?(user_file_path)
          @users = []
          return
        end

        @users = JSON.parse(File.read(user_file_path)).map do |user_object_hash|
          user = User.from_json!(user_object_hash)
          user.provider_credentials = provider_credentials_from_provider_hash_array(user: user, provider_credential_array: user.provider_credentials)
          user
        end
      end
    end

    # TODO: this could be automatic
    def provider_credentials_from_provider_hash_array(user: nil, provider_credential_array: nil)
      return provider_credential_array.map do |provider_credential_hash|
        type = provider_credential_hash["type"]

        # currently only supports 1 type, but we could automate this part too
        provider_credential = nil
        if type == FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
          provider_credential = GitHubProviderCredential.from_json!(provider_credential_hash)
          provider_credential.ci_user = user # provide backreference
        end
        provider_credential
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

    def update_user!(user: nil)
      JSONUserDataSource.file_semaphore.synchronize do
        user_index = nil
        existing_user = nil
        @users.each.with_index do |old_user, index|
          if old_user.email.casecmp(user.email.downcase).zero?
            user_index = index
            existing_user = old_user
            break
          end
        end

        if existing_user.nil?
          logger.debug("Couldn't update user #{user.email} because they don't exist")
          raise "Couldn't update user #{user.email} because they don't exist"
        else
          @users[user_index] = user # swap the old user record with the user
          logger.debug("Updating user #{existing_user.email}, writing out users.json to #{user_file_path}")
          File.write(user_file_path, JSON.pretty_generate(@users.map(&:to_object_dictionary)))
        end
      end
    end

    def create_user!(email: nil, password: nil, provider_credential: nil)
      new_user = User.new(
        id: SecureRandom.uuid,
        email: email,
        password_hash: BCrypt::Password.create(password),
        provider_credentials: [provider_credential]
      )
      JSONUserDataSource.file_semaphore.synchronize do
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
