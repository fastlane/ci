require "spec_helper"
require "app/shared/json_convertible"

class MockJSONConvertible
  include FastlaneCI::JSONConvertible

  attr_accessor :one_attribute

  attr_accessor :other_attribute

  def initialize(one_attribute: nil, other_attribute: nil)
    self.one_attribute = one_attribute
    self.other_attribute = other_attribute
  end
end

class MockParentJSONConvertible
  include FastlaneCI::JSONConvertible

  # @return [MockJSONConvertible]
  attr_accessor :mock_json_attribute

  def initialize(mock_json_attribute: nil)
    self.mock_json_attribute = mock_json_attribute
  end
end

class MockArrayJSONConvertible
  include FastlaneCI::JSONConvertible

  # @return [Array(MockJSONConvertible)]
  attr_accessor :mock_json_array_attribute

  def initialize(mock_json_array_attribute: nil)
    self.mock_json_array_attribute = mock_json_array_attribute
  end
end

class MockAttributeArrayJSONConvertible
  include FastlaneCI::JSONConvertible

  attr_accessor :one_attribute

  attr_accessor :other_attribute

  attr_accessor :array_attribute

  def initialize(one_attribute: nil, other_attribute: nil, array_attribute: nil)
    self.one_attribute = one_attribute
    self.other_attribute = other_attribute
    self.array_attribute = array_attribute
  end
end

class MockMultipleAttributeArrayJSONConvertible
  include FastlaneCI::JSONConvertible

  attr_accessor :one_array_attribute

  attr_accessor :other_array_attribute

  def initialize(one_array_attribute: nil, other_array_attribute: nil)
    self.one_array_attribute = one_array_attribute
    self.other_array_attribute = other_array_attribute
  end

  def self.map_enumerable_type(enumerable_property_name: nil, current_json_object: nil)
    if enumerable_property_name == :@one_array_attribute
      object = OpenStruct.new(current_json_object)
      object.is_from_one_array_attribute = true
      return object
    elsif enumerable_property_name == :@other_array_attribute
      object = OpenStruct.new(current_json_object)
      object.is_from_other_array_attribute = true
      return object
    end
  end
end

class MockJSONConvertibleWithRequiredParams
  include FastlaneCI::JSONConvertible

  attr_reader :one_attribute

  def initialize(one_attribute:)
    @one_attribute = one_attribute
  end
end

class MockJSONConvertibleWithMixedParams
  include FastlaneCI::JSONConvertible

  attr_reader :one_attribute

  attr_accessor :other_attribute

  def initialize(one_attribute:, other_attribute: nil)
    @one_attribute = one_attribute
    self.other_attribute = other_attribute
  end
end

class MockJSONConvertibleWithNoParams
  include FastlaneCI::JSONConvertible

  attr_accessor :one_attribute

  def initialize
  end
end

module FastlaneCI
  describe JSONConvertible do
    let (:mock_object) { MockJSONConvertible.new(one_attribute: "Hello", other_attribute: Time.at(0)) }
    let (:mock_array_object) do
      MockArrayJSONConvertible.new(mock_json_array_attribute: [
                                     MockJSONConvertible.new(one_attribute: "Hello", other_attribute: Time.at(0)),
                                     MockJSONConvertible.new(one_attribute: "World", other_attribute: Time.at(10))
                                   ])
    end

    let (:mock_array_of_hash_object) do
      MockArrayJSONConvertible.new(mock_json_array_attribute: [
                                     { one_attribute: "Hello", other_attribute: "Test" },
                                     { one_attribute: "World", other_attribute: "This" }
                                   ])
    end

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
      allow(MockJSONConvertible).to receive(:json_to_attribute_name_proc_map).and_return({ :@other_attribute => proc { |timestamp| Time.at(timestamp) } })
      object = MockJSONConvertible.from_json!({ "one_attribute" => "Hello", "other_attribute" => Time.at(0) })
      expect(object.one_attribute).to eql("Hello")
      expect(object.other_attribute).to eql(Time.at(0))
    end

    it "Allows to decode from a dictionary object using both custom value mapping and custom porperty mapping" do
      allow(MockJSONConvertible).to receive(:attribute_key_name_map).and_return({ :@one_attribute => "json_one_attribute", :@other_attribute => "json_other_attribute" })
      allow(MockJSONConvertible).to receive(:json_to_attribute_name_proc_map).and_return({ :@other_attribute => proc { |timestamp| Time.at(timestamp) } })
      object = MockJSONConvertible.from_json!({ "json_one_attribute" => "Hello", "json_other_attribute" => Time.at(0) })
      expect(object.one_attribute).to eql("Hello")
      expect(object.other_attribute).to eql(Time.at(0))
    end

    it "Allows to decode from a dictionary object when it has custom attributes" do
      allow(MockParentJSONConvertible).to receive(:attribute_to_type_map).and_return({ :@mock_json_attribute => MockJSONConvertible })
      dictionary_object = { "mock_json_attribute" => { "one_attribute" => "Hello", "other_attribute" => Time.at(0) } }
      object = MockParentJSONConvertible.from_json!(dictionary_object)
      expect(object.mock_json_attribute.one_attribute).to eql("Hello")
      expect(object.mock_json_attribute.other_attribute).to eql(Time.at(0))
    end

    it "The mapping of a class that includes `JSONConvertible` takes precedence from a custom map of a parent class" do
      allow(MockParentJSONConvertible).to receive(:attribute_to_type_map).and_return({ :@mock_json_attribute => MockJSONConvertible })
      allow(MockJSONConvertible).to receive(:json_to_attribute_name_proc_map).and_return({ :@mock_json_attribute => proc { |_|
        MockJSONConvertible.new(one_attribute: "World", other_attribute: Time.at(10))
      } })
      dictionary_object = { "mock_json_attribute" => { "one_attribute" => "Hello", "other_attribute" => Time.at(0) } }
      object = MockParentJSONConvertible.from_json!(dictionary_object)
      expect(object.mock_json_attribute.one_attribute).to eql("Hello")
      expect(object.mock_json_attribute.other_attribute).to eql(Time.at(0))
    end

    it "Allows to decode from a dictionary object when it has an array typed attribute" do
      allow(MockArrayJSONConvertible).to receive(:attribute_to_type_map).and_return({ :@mock_json_array_attribute => MockJSONConvertible })
      dictionary_object = { "mock_json_array_attribute" => [{ "one_attribute" => "Hello", "other_attribute" => Time.at(0) }, { "one_attribute" => "World", "other_attribute" => Time.at(10) }] }
      object = MockArrayJSONConvertible.from_json!(dictionary_object)
      expect(object.mock_json_array_attribute.kind_of?(Array)).to eql(true)
      expect(object.mock_json_array_attribute.length).to eql(2)
      expect(object.mock_json_array_attribute[0].kind_of?(MockJSONConvertible)).to eql(true)
      expect(object.mock_json_array_attribute[1].kind_of?(MockJSONConvertible)).to eql(true)
      expect(object.mock_json_array_attribute[0].one_attribute).to eql("Hello")
      expect(object.mock_json_array_attribute[1].one_attribute).to eql("World")
    end

    it "Allows to decode from a dictionary object using custom mapping per object in array property" do
      allow(MockArrayJSONConvertible).to receive(:map_enumerable_type).and_return(mock_object)
      dictionary_object = { "mock_json_array_attribute" => [{ "foo" => "foo" }, { "bar" => "bar" }] }
      object = MockArrayJSONConvertible.from_json!(dictionary_object)
      expect(object.mock_json_array_attribute.kind_of?(Array)).to eql(true)
      expect(object.mock_json_array_attribute.length).to eql(2)
      expect(object.mock_json_array_attribute[0]).to eql(mock_object)
      expect(object.mock_json_array_attribute[1]).to eql(mock_object)
    end

    it "map_enumerable_type customizes the output object for a given variable name" do
      object = OpenStruct.new
      object.is_from_one_array_attribute = true
      expect(
        MockMultipleAttributeArrayJSONConvertible.map_enumerable_type(
          enumerable_property_name: :@one_array_attribute,
          current_json_object: { "is_from_one_array_attribute" => true }
        )
      ).to eql(object)
      object = OpenStruct.new
      object.is_from_other_array_attribute = true
      expect(
        MockMultipleAttributeArrayJSONConvertible.map_enumerable_type(
          enumerable_property_name: :@other_array_attribute,
          current_json_object: { "is_from_other_array_attribute" => true }
        )
      ).to eql(object)
    end

    it "Allows to encode objects with array properties of a particular type" do
      array_object_dictionary = mock_array_object.to_object_dictionary
      expect(array_object_dictionary).to eql({ "mock_json_array_attribute" => [
                                               { "one_attribute" => "Hello", "other_attribute" => Time.at(0) },
                                               { "one_attribute" => "World", "other_attribute" => Time.at(10) }
                                             ] })
    end

    it "Allows to encode objects with array properties of a type that does not include the JSONConvertible mixin" do
      array_object_dictionary = mock_array_of_hash_object.to_object_dictionary
      expect(array_object_dictionary).to eql({ "mock_json_array_attribute" => [
                                               { one_attribute: "Hello", other_attribute: "Test" },
                                               { one_attribute: "World", other_attribute: "This" }
                                             ] })
    end

    it "Allows to decode objects with nested array properties" do
      mock_object = MockAttributeArrayJSONConvertible.new(one_attribute: "World", other_attribute: Time.at(10), array_attribute: [
                                                            MockJSONConvertible.new(one_attribute: "Inner World", other_attribute: Time.at(100))
                                                          ])
      dictionary_object = mock_object.to_object_dictionary
      expect(dictionary_object).to eql({ "one_attribute" => "World", "other_attribute" => Time.at(10), "array_attribute" => [
                                         { "one_attribute" => "Inner World", "other_attribute" => Time.at(100) }
                                       ] })
    end

    it "Allows to decode objects with required initialization parameters" do
      object_dictionary = { one_attribute: "rocket" }
      object = MockJSONConvertibleWithRequiredParams.from_json!(object_dictionary)
      expect(object.one_attribute).to eql("rocket")
    end

    it "Raises exception when required initialization parameters are not found" do
      object_dictionary = { not_the_attribute: "taco" }
      expect { MockJSONConvertibleWithRequiredParams.from_json!(object_dictionary) }.to(raise_exception(TypeError))
    end

    it "Allows to decode objects with mixed initialization parameters" do
      object_dictionary = { one_attribute: "cat", other_attribute: "dog" }
      object = MockJSONConvertibleWithMixedParams.from_json!(object_dictionary)
      expect(object.one_attribute).to eql("cat")
      expect(object.other_attribute).to eql("dog")
    end

    it "Allows to decode objects with no initialization parameters" do
      object_dictionary = { one_attribute: "robot" }
      object = MockJSONConvertibleWithNoParams.from_json!(object_dictionary)
      expect(object.one_attribute).to eql("robot")
    end
  end
end
