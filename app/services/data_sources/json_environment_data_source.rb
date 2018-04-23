require "bcrypt"
require_relative "json_data_source"
require_relative "environment_data_source"
require_relative "../../shared/logging_module"
require_relative "../../shared/json_convertible"
require_relative "../../shared/models/environment_variable"

module FastlaneCI
  # Mixin the JSONConvertible class for User
  class EnvironmentVariable
    include FastlaneCI::JSONConvertible
  end

  # Data source for users backed by JSON
  class JSONEnvironmentDataSource < EnvironmentDataSource
    include FastlaneCI::JSONDataSource
    include FastlaneCI::Logging

    class << self
      attr_accessor :file_semaphore
    end

    # can't have us reading and writing to a file at the same time
    JSONEnvironmentDataSource.file_semaphore = Mutex.new

    def after_creation(**params)
      logger.debug("Using folder path for environment data: #{json_folder_path}")
      # load up the json file here
      # parse all data into objects so we can fail fast on error
      reload_environment
    end

    def environment_file_path(path: "environment.json")
      File.join(json_folder_path, path)
    end

    def environment_variables
      JSONEnvironmentDataSource.file_semaphore.synchronize do
        return @environment
      end
    end

    def environment_variables=(environment_variables)
      JSONEnvironmentDataSource.file_semaphore.synchronize do
        File.write(environment_file_path, JSON.pretty_generate(environment_variables.map(&:to_object_dictionary)))
      end

      # Reload the variables to sync them up with the persisted file store
      reload_environment
    end

    def reload_environment
      JSONEnvironmentDataSource.file_semaphore.synchronize do
        unless File.exist?(environment_file_path)
          @environment = []
          return
        end

        @environment = JSON.parse(File.read(environment_file_path)).map do |user_object_hash|
          EnvironmentVariable.from_json!(user_object_hash)
        end
      end
    end

    # TODO: this isn't threadsafe
    def update_environment_variable!(environment_variable: nil)
      # TODO
      # user_index, existing_user = find_user_index_and_existing_user(user: user)

      # if existing_user.nil?
      #   logger.debug("Couldn't update user #{user.email} because they don't exist")
      #   raise "Couldn't update user #{user.email} because they don't exist"
      # else
      #   users = self.users
      #   users[user_index] = user
      #   self.users = users
      #   logger.debug("Updating user #{existing_user.email}, writing out users.json to #{environment_file_path}")
      #   return true
      # end
    end

    def delete_variable!(environment_variable: nil)
      # TODO
      # user_index, existing_user = find_user_index_and_existing_user(user: user)

      # if existing_user.nil?
      #   logger.debug("Couldn't delete user #{user.email} because they don't exist")
      #   raise "Couldn't delete user #{user.email} because they don't exist"
      # else
      #   users.delete_at(user_index)
      #   logger.debug("Deleted user #{existing_user.email}, writing out users.json to #{environment_file_path}")
      #   return true
      # end
    end

    def create_environment_variable!(key: nil, value: nil)
      # TODO
      # users = self.users
      # new_user = User.new(
      #   id: id,
      #   email: email,
      #   password_hash: BCrypt::Password.create(password),
      #   provider_credentials: provider_credentials
      # )

      # if !user_exist?(email: email)
      #   users.push(new_user)
      #   self.users = users
      #   logger.debug("Added user #{new_user.email}, writing out users.json to #{environment_file_path}")
      #   return new_user
      # else
      #   logger.debug("Couldn't add user #{new_user.email} because they already exist")
      #   return nil
      # end
    end

    # Finds a user with a given id
    #
    # @return [User]
    # def find_user(id: nil)
    #   return users.detect { |user| user.id == id }
    # end

    private

    # Finds the index of the user, and returns an existing `user` if they exist
    #
    # @param  [User] `user` a user to lookup by `user.email`
    # @return [Integer] `user_index` in the `users` array
    # @return [User] `existing_user` in the `users.json` file
    # def find_user_index_and_existing_user(user:)
    #   users.each.with_index do |old_user, index|
    #     return [index, old_user] if old_user.id == user.id
    #   end

    #   return [nil, nil]
    # end
  end
end
