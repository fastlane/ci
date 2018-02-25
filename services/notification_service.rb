require_relative "data_sources/json_notification_data_source"
require_relative "../shared/logging_module"

module FastlaneCI
  # Provides access to notification related logic
  class NotificationService
    include FastlaneCI::Logging

    # @return [NotificationDataSource]
    attr_accessor :notification_data_source

    # Instantiates `NotificationService` from notification_data_source passed in
    #
    # @param  [NotificationDataSource] notification_data_source
    # @raise  [Exception]
    # @return [nil]
    def initialize(notification_data_source: nil)
      unless notification_data_source.nil?
        raise "notification_data_source must be descendant of #{NotificationDataSource.name}" unless notification_data_source.class <= NotificationDataSource
      end


      if notification_data_source.nil?
        logger.debug("notification_data_source is new, using `ENV[\"data_store_folder\"]` if available, or `sample_data` folder")
        data_store_folder = ENV["data_store_folder"]
        data_store_folder ||= File.join(FastlaneCI::FastlaneApp.settings.root, "sample_data")
        notification_data_source = JSONNotificationDataSource.new(json_folder_path: data_store_folder)
      end

      @notification_data_source = notification_data_source
    end

    # Creates and returns a new Notification
    #
    # @param  [String] priority
    # @param  [String] name
    # @param  [String] message
    # @return [Notification]
    def create_notification!(priority: nil, name: nil, message: nil)
      unless notification_data_source.notification_exist?(name: name)
        logger.debug("creating notification #{name}")
        return notification_data_source.create_notification!(priority: priority, name: name, message: message)
      end

      logger.debug("notification #{name} already exists!")
      return nil
    end

    # Updates and persists an existing Notification
    #
    # @param  [Notification] notification
    # @return [nil]
    def update_notification!(notification: nil)
      notification_data_source.update_notification!(notification: notification)
    end

    # Deletes a notification if the 'primary key' exists
    #
    # @param  [String] name
    # @return [nil]
    def delete_notification!(name: nil)
      notification_data_source.delete_notification!(name: name)
    end
  end
end
