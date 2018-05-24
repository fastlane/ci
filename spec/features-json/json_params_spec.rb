require "spec_helper"
require "app/features-json/json_params"

describe FastlaneCI::JSONParams do
  let(:app) do
    klass = Class.new(Sinatra::Base) do
      include FastlaneCI::JSONParams
    end

    klass.new
  end

  it "parses the JSON params" do
    setup_request('{"hello":"world"}')
    expect(app.helpers.params).to eq({ "hello" => "world" })
  end

  it "allows string or symbol key lookup" do
    setup_request('{"hello":"world"}')
    expect(app.helpers.params["hello"]).to eq("world")
    expect(app.helpers.params[:hello]).to eq("world")
  end

  it "handles no input" do
    setup_request(nil)
    expect(app.helpers.params).to eq(nil)
  end

  def setup_request(input)
    app.helpers.request = Sinatra::Request.new(Rack::MockRequest.env_for("/", { method: :post, input: input }))
  end
end
