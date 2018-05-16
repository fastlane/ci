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

    def self.attribute_to_type_map
      return { :@provider_credentials => GitHubProviderCredential }
    end

    def self.map_enumerable_type(enumerable_property_name: nil, current_json_object: nil)
      if enumerable_property_name == :@provider_credentials
        type = current_json_object["type"]
        # currently only supports 1 type, but we could automate this part too
        provider_credential = nil
        if type == FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
          provider_credential = GitHubProviderCredential.from_json!(current_json_object)
        end
        provider_credential
      end
    end
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
      reload_users
    end

    def user_file_path(path: "users.json")
      File.join(json_folder_path, path)
    end

    def users
      JSONUserDataSource.file_semaphore.synchronize do
        return @users
      end
    end

    def users=(users)
      JSONUserDataSource.file_semaphore.synchronize do
        @users.each do |user|
          # Fist need to serialize the provider credentials and ignore the `ci_user`
          # instance variable. The reasoning is since if you serialize the `user`
          # first, you will call `to_object_map` on the `ci_user`, which holds
          # reference to a user. This will go on indefinitely
          user.provider_credentials.map! do |credential|
            credential.to_object_dictionary(ignore_instance_variables: [:@ci_user])
          end
        end

        File.write(user_file_path, JSON.pretty_generate(users.map(&:to_object_dictionary)))
      end

      # Reload the users to sync them up with the persisted file store
      reload_users
    end

    def reload_users
      JSONUserDataSource.file_semaphore.synchronize do
        unless File.exist?(user_file_path)
          @users = []
          return
        end

        @users = JSON.parse(File.read(user_file_path)).map do |user_object_hash|
          user = User.from_json!(user_object_hash)
          user.provider_credentials.each do |provider_credential|
            # Provide the back-reference
            provider_credential.ci_user = user
          end
          user
        end
      end
    end

    def login(email:, password:)
      user = users.detect { |existing_user| existing_user.email.casecmp(email.downcase).zero? }

      if user.nil?
        logger.debug("Couldn't find user with email #{email} in list of available accounts")
        # user doesn't exist
        return nil
      end

      # cool, the user exists, but we need to check the password
      user_password = BCrypt::Password.new(user.password_hash)

      # sweet, it matches, return the user
      if user_password == password
        logger.debug("User #{email} authenticated")
        return user
      end

      # nope, wrong password
      logger.debug("User #{email} authentication failed")
      return nil
    end

    # just check to see if we have a user with that email...
    def user_exist?(email:)
      return users.any? { |existing_user| existing_user.email.casecmp(email.downcase).zero? }
    end

    # TODO: this isn't threadsafe
    def update_user!(user:)
      user_index = user_index(user: user)

      if user_index.nil?
        logger.debug("Couldn't update user #{user.email} because they don't exist")
        raise "Couldn't update user #{user.email} because they don't exist"
      else
        users[user_index] = user
        logger.debug("Updating user #{user.email}, writing out users.json to #{user_file_path}")
      end
    end

    def delete_user!(user:)
      if find_user(id: user.id).nil?
        logger.debug("Couldn't delete user #{user.email} because they don't exist")
        raise "Couldn't delete user #{user.email} because they don't exist"
      else
        users.delete(user)
        logger.debug("Deleted user #{user.email}, writing out users.json to #{user_file_path}")
      end
    end

    def create_user!(id: nil, email:, password:, provider_credentials: [])
      users = self.users
      new_user = User.new(
        id: id,
        email: email,
        password_hash: BCrypt::Password.create(password),
        provider_credentials: provider_credentials
      )

      if !user_exist?(email: email)
        users.push(new_user)
        self.users = users
        logger.debug("Added user #{new_user.email}, writing out users.json to #{user_file_path}")
        return new_user
      else
        logger.debug("Couldn't add user #{new_user.email} because they already exist")
        return nil
      end
    end

    # Finds a user with a given `id`
    #
    # @param  [String] `id` the UUID for a user to find.
    # @return [User]
    def find_user(id:)
      return users.detect { |user| user.id == id }
    end

    private

    # Finds the index of the user, if it exists
    #
    # @param  [User] `user` a user to lookup by `user.id`
    # @return [Integer] `user_index` in the `users` array
    def user_index(user:)
      users.each.with_index { |old_user, index| return index if old_user.id == user.id }
      return nil
    end
  end
end
