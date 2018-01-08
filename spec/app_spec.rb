require File.expand_path("../spec_helper.rb", __FILE__)

describe "sinatra example" do
  it "should allow accessing the home page" do
    get "/"
    expect(last_response.status).to eq(302)
  end
end
