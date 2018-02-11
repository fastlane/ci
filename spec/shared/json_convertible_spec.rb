require_relative "../../shared/json_convertible"
require "json"

class MockJSONConvertible
  include FastlaneCI::JSONConvertible

  attr_accessor :one_attribute

  attr_accessor :other_attribute

  def initialize(one_attribute: nil, other_attribute: nil)
    self.one_attribute = one_attribute
    self.other_attribute = other_attribute
  end
end

module FastlaneCI
  describe JSONConvertible do
    let (:mock_object) { MockJSONConvertible.new(one_attribute: "Hello", other_attribute: Time.at(0)) }

    it "Works out of the box with serialization to object dictionary" do
      json_from_mock_object = mock_object.to_object_dictionary

      expect(json_from_mock_object).to eql({ "one_attribute" => "Hello", "other_attribute" => Time.at(0) })
    end

    it "Allows to object dictionary with custom property mapping" do
      allow(MockJSONConvertible).to receive(:attribute_key_name_map).and_return({ :@one_attribute => "json_one_attribute" })
      json_from_mock_object = mock_object.to_object_dictionary
      expect(json_from_mock_object).to eql({ "json_one_attribute" => "Hello", "other_attribute" => Time.at(0) })
    end

    it "Allows to perform custom mappings of the values for a given attribute when converting to JSON" do
      allow(MockJSONConvertible).to receive(:attribute_name_to_json_proc_map).and_return({ :@other_attribute => proc { |timestamp| timestamp.strftime("%G-W%V-%uT%R%:z") } })
      json_from_mock_object = mock_object.to_object_dictionary
      expect(json_from_mock_object).to eql({ "one_attribute" => "Hello", "other_attribute" => Time.at(0).strftime("%G-W%V-%uT%R%:z") })
    end

    it "Allows to perform custom property mapping and value mapping at the same time" do
      allow(MockJSONConvertible).to receive(:attribute_key_name_map).and_return({ :@one_attribute => "json_one_attribute", :@other_attribute => "json_other_attribute" })
      allow(MockJSONConvertible).to receive(:attribute_name_to_json_proc_map).and_return({ :@other_attribute => proc { |timestamp| timestamp.strftime("%G-W%V-%uT%R%:z") } })
      json_from_mock_object = mock_object.to_object_dictionary
      expect(json_from_mock_object).to eql({ "json_one_attribute" => "Hello", "json_other_attribute" => Time.at(0).strftime("%G-W%V-%uT%R%:z") })
    end

    it "Allows to decode from a dictionary object" do
      object_dictionary = { "one_attribute" => "Hello", "other_attribute" => Time.at(0) }
      expect { MockJSONConvertible.from_json!(object_dictionary) }.to_not(raise_exception)
      object = MockJSONConvertible.from_json!(object_dictionary)
      expect(object.one_attribute).to eql("Hello")
      expect(object.other_attribute).to eql(Time.at(0))
    end

    it "Allows to decode from a dictionary object using custom property mapping" do
      allow(MockJSONConvertible).to receive(:attribute_key_name_map).and_return({ :@one_attribute => "json_one_attribute" })
      object = MockJSONConvertible.from_json!({ "json_one_attribute" => "Hello", "other_attribute" => Time.at(0) })
      expect(object.one_attribute).to eql("Hello")
      expect(object.other_attribute).to eql(Time.at(0))
    end

    it "Allows to decode from a dictionary object using custom value mapping" do
      allow(MockJSONConvertible).to receive(:json_to_attribute_name_proc_map).and_return({ :@other_attribute => proc { |timestamp| Time.parse(timestamp) } })
      object = MockJSONConvertible.from_json!({ "one_attribute" => "Hello", "other_attribute" => Time.at(0) })
      expect(object.one_attribute).to eql("Hello")
      expect(object.other_attribute).to eql(Time.at(0))
    end

    it "Allows to decode from a dictionary object using both custom value mapping and custom porperty mapping" do
      allow(MockJSONConvertible).to receive(:attribute_key_name_map).and_return({ :@one_attribute => "json_one_attribute", :@other_attribute => "json_other_attribute" })
      allow(MockJSONConvertible).to receive(:json_to_attribute_name_proc_map).and_return({ :@other_attribute => proc { |timestamp| Time.parse(timestamp) } })
      object = MockJSONConvertible.from_json!({ "json_one_attribute" => "Hello", "json_other_attribute" => Time.at(0) })
      expect(object.one_attribute).to eql("Hello")
      expect(object.other_attribute).to eql(Time.at(0))
    end
  end
end
