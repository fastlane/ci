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
    include FastlaneCI::Logging

    class << self
      attr_accessor :file_semaphore
    end

    # Can't have us reading and writing to a file at the same time
    JSONNotificationDataSource.file_semaphore = Mutex.new

    # Instantiates a new `JSONNotificationDataSource` object
    #
    # @param  [String] json_folder_path
    # @return [nil]
    def initialize(json_folder_path: nil)
      @json_folder_path = json_folder_path
      logger.debug("Using folder path for notification data: #{json_folder_path}")
      reload_notifications
    end

    # Returns array of notifications from JSON file
    #
    # @return [Array[Notification]]
    def notifications
      JSONNotificationDataSource.file_semaphore.synchronize { return @notifications }
    end

    # Returns `true` if the notification exists in the in-memory notifications object
    #
    # @param  [String] name
    # @param  [String] message
    # @return [Boolean]
    def notification_exist?(name: nil, message: nil)
      notification = @notifications.select do |n|
        n.primary_key == Notification.make_primary_key(name)
      end.first

      return notification.nil? ? false : true
    end

    # Swaps the old notification record with the updated notification record if
    # the notification exists
    #
    # @param  [Notification] notification
    # @return [nil]
    def update_notification!(notification: nil)
      notification.updated_at = Time.now

      JSONNotificationDataSource.file_semaphore.synchronize do
        notification_index = nil
        existing_notification = nil

        @notifications.each.with_index do |old_notification, index|
          if old_notification.primary_key == notification.primary_key
            notification_index = index
            existing_notification = old_notification
            break
          end
        end

        if existing_notification.nil?
          error_message = "Couldn't update notification #{notification.name} because it doesn't exist"
          logger.debug(error_message)
          raise error_message
        else
          @notifications[notification_index] = notification
          logger.debug("Updating notification #{existing_notification.name}, writing out notifications.json to #{notifications_file_path}")
          File.write(notifications_file_path, JSON.pretty_generate(@notifications.map(&:to_object_dictionary)))
        end
      end
    end

    # Creates and returns a new notification object. Writes said object to `notifications.json`
    #
    # @param  [String] priority
    # @param  [String] name
    # @param  [String] message
    # @return [Notification]
    def create_notification!(priority: nil, name: nil, message: nil)
      new_notification = Notification.new(id: SecureRandom.uuid, priority: priority, name: name, message: message)

      JSONNotificationDataSource.file_semaphore.synchronize do
        existing_notification = @notifications.select { |notification| notification.primary_key == new_notification.primary_key }.first

        if existing_notification.nil?
          @notifications << new_notification
          logger.debug("Added notification #{new_notification.name}, writing out notifications.json to #{notifications_file_path}")
          File.write(notifications_file_path, JSON.pretty_generate(@notifications.map(&:to_object_dictionary)))
          return new_notification
        else
          logger.debug("Couldn't add notification #{notification.name} because it already exists")
          return nil
        end
      end
    end

    # Deletes a notification if it matches the primary key
    #
    # @param  [String] name
    # @return [nil]
    def delete_notification!(name: nil)
      JSONNotificationDataSource.file_semaphore.synchronize do
        primary_key = Notification.make_primary_key(name)
        @notifications.delete_if { |notification| notification.primary_key == primary_key }
      end
    end

    private

    # @return [String]
    attr_accessor :json_folder_path

    # Returns the file path for the notifications to be read from / persisted to
    #
    # @param  [String] path
    # @return [String]
    def notifications_file_path(path: "notifications.json")
      File.join(json_folder_path, path)
    end

    # Reloads the notifications from the data source
    #
    # @return [nil]
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
