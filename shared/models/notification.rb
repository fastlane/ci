require "securerandom"

module FastlaneCI
  # All metadata about a notification.
  class Notification
    # Is a UDID so we're not open to ID guessing attacks
    #
    # @return [String]
    attr_accessor :id

    # The relative priority of a notification
    #
    # @return [String]
    attr_accessor :priority

    # The name of a notification, which combined with the message can uniquely
    # specify it
    #
    # @return [String]
    attr_accessor :name

    # Notification message to be displayed in the dashboard
    #
    # @return [String]
    attr_accessor :message

    # The time the notification was created
    #
    # @return [String]
    attr_accessor :created_at

    # The last time the notification was updated
    #
    # @return [String]
    attr_accessor :updated_at

    # Instantiates a new `Notification` model object
    #
    # @param  [String] id
    # @param  [String] priority
    # @param  [String] name
    # @param  [String] message
    # @return [nil]
    def initialize(id: nil, priority: nil, name: nil, message: nil, created_at: nil, updated_at: nil)
      self.id = id || SecureRandom.uuid
      self.priority = %w[HIGH MEDIUM LOW].include?(priority) ? priority : "LOW"
      self.name = name
      self.message = message
      self.created_at = created_at || Time.now.to_s
      self.updated_at = updated_at || Time.now.to_s
    end

    # A way to uniquely specify a notification
    #
    # @return [String]
    def primary_key
      @primary_key ||= self.class.make_primary_key(name, message)
    end

    # Static method for converting notification data into primary key to
    # uniquely specify the notification
    #
    # @param  [String] name
    # @param  [String] message
    # @return [String]
    def self.make_primary_key(name, message)
      name.gsub(/\s+/, "").downcase + ":" + message.gsub(/\s+/, "").downcase
    end
  end
end
