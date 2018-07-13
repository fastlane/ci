# `services/json_deserializers`

This directory contains all JSON deserialization services, which have methods to parse JSON and return concrete object instances.

A JSON deserializer class should be written when you have a JSON representation of an abstract base class, and wish to return a concretion based on some kind of conditional logic (i.e., a `case` statement with a `type` field).

### Example `JSONTriggerDeserializer`

We wish to parse a JSON representation of an abstract `JobTrigger` and return a concrete object instance (i.e., a `CommitJobTrigger`, `PullRequestJobTrigger`, `NightlyJobTrigger`, or `ManualJobTrigger`).

We can do this by creating a `JSONTriggerDeserializer` concretion implementing the public interface for the `JSONDeserializer` class (i.e., by writing the body of the `deserialize!` method).

#### Concretion Example

```ruby
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

```

#### Usage Example

```ruby
deserializer = JSONTriggerDeserializer.new
deserializer.deserialize!(type: some_type, object: some_json_object)
```
