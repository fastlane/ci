require_relative "json_deserializer"

module FastlaneCI
  # Concrete class for deserializing JSON representations of `JobTrigger`s.
  class JSONTriggerDeserializer < JSONDeserializer
    # Deserializes a `JobTrigger` JSON representation and returns a new
    # `JobTrigger` object instance.
    #
    # @param  [String] type: The type of job trigger to return.
    # @param  [JSON] object: The object to be deserialized.
    # @return [JobTrigger]
    def deserialize!(type:, object:)
      return case type
             when FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit]
               CommitJobTrigger.from_json!(object)
             when FastlaneCI::JobTrigger::TRIGGER_TYPE[:pull_request]
               PullRequestJobTrigger.from_json!(object)
             when FastlaneCI::JobTrigger::TRIGGER_TYPE[:nightly]
               NightlyJobTrigger.from_json!(object)
             when FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual]
               ManualJobTrigger.from_json!(object)
             else
               raise "Unable to parse JobTrigger type: #{type} from #{object}"
             end
    end
  end
end
