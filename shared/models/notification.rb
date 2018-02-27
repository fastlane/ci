require "securerandom"

module FastlaneCI
  # All metadata about a notification.
  class Notification
    # Enum for notification priority
    #
    # @return [Hash]
    PRIORITIES = {
      urgent: "urgent",
      normal: "normal",
      success: "success"
    }

    # Enum for notification type
    #
    # @return [Hash]
    TYPES = {
      acknowledgement_required: "acknowledgement_required",
      disappearing: "disappearing"
    }

    # Is a UDID so we're not open to ID guessing attacks
    #
    # @return [String]
    attr_accessor :id

    # The relative priority of a notification
    #
    # @return [String]
    attr_accessor :priority

    # The type of a notification
    #
    # @return [String]
    attr_accessor :type

    # The id of the user the notification is associated with
    #
    # @return [String]
    attr_accessor :user_id

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
    # @param  [String] type
    # @param  [String] user_id
    # @param  [String] name
    # @param  [String] message
    def initialize(id: nil, priority: nil, type: nil, user_id: nil, name: nil, message: nil, created_at: nil, updated_at: nil)
      self.id = id || SecureRandom.uuid
      self.priority = priority
      self.type = type
      self.name = name
      self.user_id = user_id
      self.message = message
      self.created_at = created_at || Time.now.to_s
      self.updated_at = updated_at || Time.now.to_s

      # The `from_json!` method does not allow validations, since it creates the
      # instance with all values set to `nil`
      validate_initialization_params! unless type.nil? && priority.nil?
    end

    private

    #####################################################
    # @!group Validations: model specific validations
    #####################################################

    # Performs validations on the notification initialization parameters
    #
    # @raise [StandardError]
    def validate_initialization_params!
      validate_priority!
      validate_type!
    end

    # Validates the priority of the notification is in the `PRIORITIES` enum
    #
    # @raise [StandardError]
    def validate_priority!
      raise StandardError unless PRIORITIES.values.include?(self.priority)
    end

    # Validates the type of the notification is in the `TYPE` enum
    #
    # @raise [StandardError]
    def validate_type!
      raise StandardError unless TYPES.values.include?(self.type)
    end
  end
end
