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

    # Can't have us reading and writing to a file at the same time
    JSONNotificationDataSource.file_semaphore = Mutex.new

    # Reloads notifications from the notifications data source after instantiation
    #
    # @param [Any] params
    def after_creation(**params)
      reload_notifications
    end

    # Returns an array of notifications from the notifications JSON file stored
    # in the notifications directory
    #
    # @return [Array[Notification]]
    def notifications
      JSONProjectDataSource.projects_file_semaphore.synchronize do
        return unless File.exist?(notifications_file_path)

        return JSON.parse(File.read(notifications_file_path))
                   .map(&Notification.method(:from_json!))
      end
    end

    # Writes the notifications array to the notifications directory as JSON
    #
    # @param  [Array[Notification]] notifications
    def notifications=(notifications)
      JSONNotificationDataSource.file_semaphore.synchronize do
        return unless File.exist?(notifications_file_path)

        File.write(
          notifications_file_path,
          JSON.pretty_generate(notifications.map(&:to_object_dictionary))
        )
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
        path = notifications_file_path
        notification_name = existing_notification.name
        logger.debug("Updating notification #{notification_name}, writing out notifications.json to #{path}")
      end
    end

    # Creates and returns a new notification object. Writes said object to `notifications.json`
    #
    # @param  [String] id
    # @param  [String] priority
    # @param  [String] type
    # @param  [String] user_id
    # @param  [String] name
    # @param  [String] message
    # @return [Notification]
    def create_notification!(id: nil, priority: nil, type: nil, user_id: nil, name: nil, message: nil)
      new_notification = Notification.new(
        priority: priority,
        type: type,
        user_id: user_id,
        name: name,
        message: message
      )

      if !notification_exist?(id: new_notification.id)
        self.notifications = @notifications.push(new_notification)
        logger.debug(
          "Added notification #{new_notification.name}, writing out notifications.json to #{notifications_file_path}"
        )
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
    #   ~/.fastlane/ci/notifications/notifications.json
    #
    # @param  [String] path
    # @return [String]
    def notifications_file_path(path: "notifications/notifications.json")
      return File.join(json_folder_path, path)
    end

    # Reloads the notifications from the data source
    def reload_notifications
      JSONNotificationDataSource.file_semaphore.synchronize do
        @notifications =
          if !File.exist?(notifications_file_path)
            File.write(notifications_file_path, "[]")
            []
          else
            JSON.parse(File.read(notifications_file_path)).map do |notification_object_hash|
              Notification.from_json!(notification_object_hash)
            end
          end
      end
    end
  end
end
