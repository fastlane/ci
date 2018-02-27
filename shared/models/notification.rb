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

    # The type of a notification
    #
    # @return [String]
    attr_accessor :type

    # The user email the notification is associated with
    #
    # @return [String]
    attr_accessor :email

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
    # @param  [String] type
    # @param  [String] name
    # @param  [String] email
    # @param  [String] message
    def initialize(id: nil, priority: nil, type: nil, name: nil, email: nil, message: nil, created_at: nil, updated_at: nil)
      self.id = id || SecureRandom.uuid
      self.priority = %w[HIGH MEDIUM LOW].include?(priority) ? priority : "LOW"
      self.type = %w[acknowledgement_required disappearing].include?(type) ? type : "acknowledgement_required"
      self.name = name
      self.email = email
      self.message = message
      self.created_at = created_at || Time.now.to_s
      self.updated_at = updated_at || Time.now.to_s
    end
  end
end
