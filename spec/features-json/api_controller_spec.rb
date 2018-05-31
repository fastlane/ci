require "spec_helper"
require "app/features-json/api_controller"

describe FastlaneCI::APIController do
  ##
  # some example usages of APIController, with default authentication and with authentication disabled.
  #
  describe "by default" do
    class MySecureApiController < FastlaneCI::APIController
      get("/") do
        json({ message: "ok" })
      end

      get("/public", authenticate: false) do
        json({ message: "ok" })
      end

      get("/private") do
        json({ message: "secret" })
      end
    end

    let(:app) { MySecureApiController.new }

    describe "unauthenticated request" do
      it "index is not successful" do
        get("/")
        expect(last_response).to_not(be_ok)
        expect(last_response.body).to eq("A token must be passed.")
      end

      it "public is successful" do
        get("/public")
        expect(last_response).to(be_ok)
        expect(last_response.body).to eq('{"message":"ok"}')
      end

      it "private is not successful" do
        get("/private")
        expect(last_response).to_not(be_ok)
        expect(last_response.body).to eq("A token must be passed.")
      end
    end

    describe "authenticated request" do
      before do
        header("Authorization", bearer_token)
      end

      it "index is successful" do
        get("/")
        expect(last_response).to be_ok
        expect(last_response.body).to eq('{"message":"ok"}')
      end

      it "private is successful" do
        get("/private")
        expect(last_response).to be_ok
        expect(last_response.body).to eq('{"message":"secret"}')
      end
    end
  end

  describe "with authentication disabled" do
    class MyMixedAuthApiController < FastlaneCI::APIController
      disable(:authentication)

      get("/") do
        json({ message: "ok" })
      end

      get("/private", authenticate: :jwt) do
        json({ message: "secret" })
      end
    end

    let(:app) { MyMixedAuthApiController.new }

    describe "unathenticated request" do
      it "index is successful" do
        get("/")
        expect(last_response).to be_ok
        expect(last_response.body).to eq('{"message":"ok"}')
      end

      it "private is not successful" do
        get("/private")
        expect(last_response).to_not(be_ok)
        expect(last_response.body).to eq("A token must be passed.")
      end
    end

    describe "authenticated request" do
      before do
        header("Authorization", bearer_token)
      end

      it "index is successful" do
        get("/")
        expect(last_response).to be_ok
        expect(last_response.body).to eq('{"message":"ok"}')
      end

      it "private is successful" do
        get("/private")
        expect(last_response).to be_ok
        expect(last_response.body).to eq('{"message":"secret"}')
      end
    end
  end

  describe "helper methods" do
    let(:app) { FastlaneCI::APIController.new }

    before do
      app.settings.jwt_secret = jwt_secret
      # test helper methods outside the request/response cycle.
      # we are setting up a request like this.
      app.helpers.request = Sinatra::Request.new(Rack::MockRequest.env_for("/", { "HTTP_AUTHORIZATION" => bearer_token }))
    end

    describe "jwt authentication" do
      it "will successfully decode a token" do
        payload = app.helpers.authenticate!(via: :jwt)
        expect(payload).to include("iss", "sub", "user", "iat")
      end

      it "will halt with an error if the token is not valid" do
        app.helpers.request = Sinatra::Request.new(Rack::MockRequest.env_for("/", { "HTTP_AUTHORIZATION" => "Bearer something-else" }))
        expect do
          app.helpers.authenticate!(via: :jwt)
        end.to throw_symbol(:halt)

        app.helpers.request = Sinatra::Request.new(Rack::MockRequest.env_for("/", {}))
        expect do
          app.helpers.authenticate!(via: :jwt)
        end.to throw_symbol(:halt)
      end
    end

    describe "user authentication methods" do
      it "returns the `user` property from the JWT token" do
        expect(app.helpers.user_id).to eq("1")
      end

      it "return a user from the user service" do
        expect(FastlaneCI::Services.user_service).to receive(:find_user).with(id: "1").and_return(double("User"))
        app.helpers.current_user
      end
    end
  end
end
