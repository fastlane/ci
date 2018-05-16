require "jwt"

require "spec_helper"
require "app/features-json/middleware/jwt_auth"

describe FastlaneCI::JwtAuth do
  let(:inner_app) { ->(env) { [200, env, "app"] } }
  let(:app) { described_class.new(inner_app, "fastlane-ci-test") }

  context "Client makes a request without authentication headers" do

    it "Returns a 401 status" do
      get("/buy/tacos")
      expect(last_response.status).to eql(401)
      expect(last_response.body).to eql("A token must be passed.")
    end
  end

  context "Client makes a request with an expired authentication token" do
    let(:data) { { user: "fastlane", iat: Time.at(0), exp: Time.at(0), iss: "fastlane.ci" } }
    let(:token) { JWT.encode(data, "fastlane-ci-test", "HS256") }
    let(:expired_authorization) { "Bearer #{token}" }

    it "Returns a 401 status" do
      header("Authorization", expired_authorization)
      get("/buy/tacos")

      expect(last_response.status).to eql(401)
      expect(last_response.body).to eql("The token has expired.")
    end
  end

  context "Client makes a request with an invalid issued at time" do
    let(:data) { { user: "fastlane", iat: "an invalid iat", iss: "fastlane.ci" } }
    let(:token) { JWT.encode(data, "fastlane-ci-test", "HS256") }
    let(:invalid_authorization) { "Bearer #{token}" }

    it "Returns a 403 status" do
      header("Authorization", invalid_authorization)
      get("/buy/tacos")

      expect(last_response.status).to eql(403)
      expect(last_response.body).to eql('The token does not have a valid "issued at" time.')
    end
  end

  context "Client makes a request with an invalid issuer" do
    let(:data) { { user: "fastlane", iat: Time.now.to_i, exp: Time.now.to_i + 60 } }
    let(:token) { JWT.encode(data, "fastlane-ci-test", "HS256") }
    let(:invalid_issuer) { "Bearer #{token}" }

    it "Returns a 403 status" do
      header("Authorization", invalid_issuer)
      get("/buy/tacos")

      expect(last_response.status).to eql(403)
      expect(last_response.body).to eql("The token does not have a valid issuer.")
    end
  end

  context "Client makes a request with missing payload" do
    let(:data) { { iat: Time.now.to_i, exp: Time.now.to_i + 60, iss: "fastlane.ci" } }
    let(:token) { JWT.encode(data, "fastlane-ci-test", "HS256") }
    let(:invalid_data) { "Bearer #{token}" }

    it "Returns a 400 status" do
      header("Authorization", invalid_data)
      get("/buy/tacos")

      expect(last_response.status).to eql(500)
    end
  end
end
