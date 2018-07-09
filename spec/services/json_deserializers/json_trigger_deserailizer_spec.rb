require "spec_helper"
require "app/services/json_deserializers/json_trigger_deserializer"

describe FastlaneCI::JSONTriggerDeserializer do
  let(:deserializer) { FastlaneCI::JSONTriggerDeserializer.new }

  let(:commit_trigger_json) do
    JSON.parse('{ "type": "commit", "branch": "master" }')
  end

  let(:pull_request_trigger_json) do
    JSON.parse('{ "type": "pull_request", "branch": "master" }')
  end

  let(:nightly_trigger_json) do
    JSON.parse('{ "type": "nightly", "branch": "master" }')
  end

  let(:manual_trigger_json) do
    JSON.parse('{ "type": "manual", "branch": "master" }')
  end

  describe "#deserialize!" do
    context "FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit]" do
      it "parses the JSON correctly, and returns a `CommitJobTrigger` instance" do
        result = deserializer.deserialize!(type: "commit", object: commit_trigger_json)
        expect(result).to be_an_instance_of(FastlaneCI::CommitJobTrigger)
      end
    end

    context "FastlaneCI::JobTrigger::TRIGGER_TYPE[:pull_request]" do
      it "parses the JSON correctly, and returns a `PullRequestJobTrigger` instance" do
        result = deserializer.deserialize!(type: "pull_request", object: pull_request_trigger_json)
        expect(result).to be_an_instance_of(FastlaneCI::PullRequestJobTrigger)
      end
    end

    context "FastlaneCI::JobTrigger::TRIGGER_TYPE[:nightly]" do
      it "parses the JSON correctly, and returns a `NightlyJobTrigger` instance" do
        result = deserializer.deserialize!(type: "nightly", object: nightly_trigger_json)
        expect(result).to be_an_instance_of(FastlaneCI::NightlyJobTrigger)
      end
    end

    context "FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual]" do
      it "parses the JSON correctly, and returns a `ManualJobTrigger` instance" do
        result = deserializer.deserialize!(type: "manual", object: manual_trigger_json)
        expect(result).to be_an_instance_of(FastlaneCI::ManualJobTrigger)
      end
    end

    context "bad trigger type" do
      it "throws an exception due to not recognizing the trigger type" do
        expect { deserializer.deserialize!(type: "bad_type", object: nil) }.to raise_error
      end
    end
  end
end
