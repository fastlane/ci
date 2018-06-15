require "securerandom"

module FastlaneCI
  # All metadata about a notification.
  class Notification
    # Enum for notification priority
    #
    # @return [Hash]
    PRIORITIES = {
      warn: "warn",
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

    # Is a UUID so we're not open to ID guessing attacks
    #
    # @return [String]
    attr_reader :id

    # The relative priority of a notification
    #
    # @return [String]
    attr_reader :priority

    # The type of a notification
    #
    # @return [String]
    attr_reader :type

    # The id of the user the notification is associated with
    #
    # @return [String]
    attr_reader :user_id

    # The name of a notification, which combined with the message can uniquely
    # specify it
    #
    # @return [String]
    attr_reader :name

    # Notification message to be displayed in the dashboard
    #
    # @return [String]
    attr_reader :message

    # Notification message details that might help debugging, generally exception.message, not user-friendly
    #
    # @return [String]
    attr_accessor :details

    # The time the notification was created
    #
    # @return [String]
    attr_reader :created_at

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
    # @param  [String] details
    def initialize(
      id: nil,
      priority: nil,
      type: nil,
      user_id: nil,
      name: nil,
      message: nil,
      created_at: nil,
      updated_at: nil,
      details: nil
    )
      @id = id || SecureRandom.uuid
      @priority = priority || Notification::PRIORITIES[:normal]
      @type = type
      @name = name
      @user_id = user_id
      @message = message
      @details = details
      @created_at = created_at || Time.now.to_s
      @updated_at = updated_at || Time.now.to_s

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

      # TODO: enable validate_type! when we decide that we need it
      # validate_type!
    end

    # Validates the priority of the notification is in the `PRIORITIES` enum
    #
    # @raise [StandardError]
    def validate_priority!
      raise StandardError unless PRIORITIES.values.include?(priority)
    end

    # Validates the type of the notification is in the `TYPE` enum
    #
    # @raise [StandardError]
    def validate_type!
      raise StandardError unless TYPES.values.include?(type)
    end
  end
end
