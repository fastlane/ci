require_relative "../../../app/shared/utils/typesafe_accessor/typesafe_accessor"

class Klass
  typesafe_accessor :name, String
end

describe :typesafe_accessor do
  it "Sets and gets correctly the attribute when type matches" do
    k = Klass.new
    expect do
      k.name = "A String"
    end.to_not(raise_error(ArgumentError))
    expect(k.name).to eql("A String")
  end

  it "Raises when wrong type provided" do
    k = Klass.new
    expect do
      k.name = 123_456
    end.to(raise_error(ArgumentError))
    expect(k.name).to eql(nil)
  end
end
