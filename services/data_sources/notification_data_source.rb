module FastlaneCI
  # Abstract base class denoting operations for all things related to
  # notifications
  #
  # @abstract
  class NotificationDataSource
    # Returns all notifications from the system
    #
    # @abstract
    def notifications
      not_implemented(__method__)
    end

    # Checks if a notification exists with the same name and message
    #
    # @abstract
    def notification_exist?(name: nil, message: nil)
      not_implemented(__method__)
    end

    # Updates the notification status
    #
    # @abstract
    def update_notification!(notification: nil)
      not_implemented(__method__)
    end

    # Creates and returns a notification
    #
    # @abstract
    def create_notification!(priority: nil, name: nil, message: nil)
      not_implemented(__method__)
    end
  end
end
