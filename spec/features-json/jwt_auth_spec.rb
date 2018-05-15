require "spec_helper"
require "app/features-json/middleware/jwt_auth"

describe FastlaneCI::JwtAuth do
  let(:app) { ->(env) { [200, env, "app"] } }
  let(:middleware) { described_class.new(app) }

  context "Client makes a request without authentication headers" do
    let(:request) { Rack::MockRequest.new(middleware) }
    let(:response) { request.get("/buy/tacos") }

    it "Returns a 401 status" do
      expect(response.status).to eql(401)
    end
  end

  context "Client makes a request with an expired authentication token" do
    let(:request) { Rack::MockRequest.new(middleware) }
    let(:expired_header) { { "HTTP_AUTHORIZATION": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjExNjM5MjYxLCJpYXQiOjExNjM5MjYxLCJpc3MiOiJmYXN0bGFuZS5jaSJ9._wzA6VzEuex1wJZctYHk94lCDMydOIe7scENvsCqTes" } }
    let(:response) { request.get("/buy/tacos", expired_header) }

    it "Returns a 403 status" do
      expect(response.status).to eql(403)
    end
  end
end
