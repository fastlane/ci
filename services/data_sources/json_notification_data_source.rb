require "securerandom"
require_relative "notification_data_source"
require_relative "../../shared/logging_module"
require_relative "../../shared/json_convertible"
require_relative "../../shared/models/notification"

module FastlaneCI
  # Mixin the JSONConvertible class for Notification
  class Notification
    include FastlaneCI::JSONConvertible
  end

  # Data source for notifications backed by JSON
  class JSONNotificationDataSource < NotificationDataSource
    include FastlaneCI::JSONDataSource
    include FastlaneCI::Logging

    class << self
      attr_accessor :file_semaphore
    end

    # @return [FastlaneCI::GitRepo]
    attr_accessor :git_repo

    # Can't have us reading and writing to a file at the same time
    JSONNotificationDataSource.file_semaphore = Mutex.new

    # Reloads notifications from the notifications data source after instantiation
    #
    # @param  [Any] params
    def after_creation(**params)
      if params.nil?
        raise "Either user or a provider credential is mandatory."
      else
        if !params[:user] && !params[:provider_credential]
          raise "Either user or a provider credential is mandatory."
        else
          params[:provider_credential] ||= params[:user].provider_credential(type: ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github])
          @git_repo = FastlaneCI::GitRepo.new(git_config: self.json_folder_path, provider_credential: params[:provider_credential])
        end
      end

      reload_notifications
    end

    # Returns an array of notifications from the notifications JSON file stored
    # in the configuration git repo
    #
    # @return [Array[Notification]]
    def notifications
      JSONProjectDataSource.projects_file_semaphore.synchronize do
        path = git_repo.file_path("notifications.json")
        return [] unless File.exist?(path)

        return JSON.parse(File.read(path)).map(&Notification.method(:from_json!))
      end
    end

    # Writes the notifications array to the git repo as JSON and commit them as
    # the CI user
    #
    # @param  [Array[Notification]] notifications
    def notifications=(notifications)
      JSONNotificationDataSource.file_semaphore.synchronize do
        File.write(notifications_file_path, JSON.pretty_generate(notifications.map(&:to_object_dictionary)))
        git_repo.commit_changes!
      end
    end

    # Returns `true` if the notification exists in the in-memory notifications object
    #
    # @param  [String] id
    # @return [Boolean]
    def notification_exist?(id: nil)
      JSONNotificationDataSource.file_semaphore.synchronize do
        return @notifications.any? { |notification| notification.id == id }
      end
    end

    # Swaps the old notification record with the updated notification record if
    # the notification exists
    #
    # @param  [Notification] notification
    def update_notification!(notification: nil)
      notification.updated_at = Time.now

      notification_index = nil
      existing_notification = nil

      @notifications.each.with_index do |old_notification, index|
        if old_notification.id == notification.id
          notification_index = index
          existing_notification = old_notification
          break
        end
      end

      if existing_notification.nil?
        error_message = "Couldn't update notification #{notification.name} because it doesn't exist"
        logger.error(error_message)
        raise error_message
      else
        @notifications[notification_index] = notification
        self.notifications = @notifications
        logger.debug("Updating notification #{existing_notification.name}, writing out notifications.json to #{notifications_file_path}")
      end
    end

    # Creates and returns a new notification object. Writes said object to `notifications.json`
    #
    # @param  [String] id
    # @param  [String] priority
    # @param  [String] type
    # @param  [String] name
    # @param  [String] message
    # @return [Notification]
    def create_notification!(id: nil, priority: nil, type: nil, name: nil, message: nil)
      new_notification = Notification.new(priority: priority, type: type, name: name, message: message)

      if !notification_exist?(id: new_notification.id)
        self.notifications = @notifications.push(new_notification)
        logger.debug("Added notification #{new_notification.name}, writing out notifications.json to #{notifications_file_path}")
        return new_notification
      else
        logger.debug("Couldn't add notification #{notification.name} because it already exists")
        return nil
      end
    end

    # Deletes a notification if it matches the `id` passed in
    #
    # @param  [String] id
    def delete_notification!(id: nil)
      self.notifications = @notifications.delete_if { |notification| notification.id == id }
    end

    private

    # Returns the file path for the notifications to be read from / persisted to
    #
    # @param  [String] path
    # @return [String]
    def notifications_file_path(path: "notifications.json")
      git_repo.file_path("notifications.json")
    end

    # Reloads the notifications from the data source
    def reload_notifications
      JSONNotificationDataSource.file_semaphore.synchronize do
        @notifications = []
        return unless File.exist?(notifications_file_path)

        @notifications = JSON.parse(File.read(notifications_file_path)).map do |notification_object_hash|
          Notification.from_json!(notification_object_hash)
        end
      end
    end
  end
end
