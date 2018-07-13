require "spec_helper"
require "app/features-json/setup_json_controller"

describe FastlaneCI::SetupJSONController do
  let(:app) { described_class.new }
  let(:json) { JSON.parse(last_response.body) }

  before do
    header("Authorization", bearer_token)
  end

  describe "POST /data/setup" do
    describe "Successful onboarding" do
      before do
        expect(FastlaneCI::Services.onboarding_service).to receive(:correct_setup?).and_return(false)
      end

      it "works as expected and all values are stored locally" do
        email_entry = "email_entry"
        expect(email_entry).to receive(:primary).and_return(true)
        expect(email_entry).to receive(:email).and_return("email@email.com")

        expect(FastlaneCI::Services.onboarding_user_client).to receive(:emails).and_return([email_entry])
        expect(FastlaneCI::Services.configuration_repository_service).to receive(:setup_private_configuration_repo).and_return(nil)
        expect(FastlaneCI::Services.onboarding_service).to receive(:clone_remote_repository_locally).and_return(nil)
        expect(FastlaneCI::Services).to receive(:reset_services!).and_return(nil) # we don't want this, as we stub all the things
        expect(FastlaneCI::GitHubService).to receive(:token_scope_validation_error).and_return(nil).twice

        class FastlaneCI::Launch
        end
        expect(FastlaneCI::Launch).to receive(:start_github_workers)

        keys_writer = "keys_writer"
        expect(keys_writer).to receive(:write!).and_return(nil)

        expected_parameters = {
          path: "#{ENV['HOME']}/.fastlane/ci/.keys",
          locals: {
            ci_base_url: FastlaneCI.dot_keys.ci_base_url,
            encryption_key: "encryption_key",
            ci_user_password: "password",
            ci_user_api_token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            repo_url: "https://github.com/fastlane/ci-config",
            initial_onboarding_user_api_token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          }
        }

        expect(FastlaneCI::KeysWriter).to receive(:new).with(expected_parameters).and_return(keys_writer)

        post("/data/setup", {
          encryption_key: "encryption_key",
          bot_account: {
            token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            password: "password"
          },
          config_repo: "https://github.com/fastlane/ci-config",
          initial_onboarding_token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        }.to_json)

        expect(last_response.status).to eq(200)
        expect(json).to eq({})
      end
    end

    describe "Error cases" do
      describe "Already setup" do
        it "should fail immediately if a ci-config repo is already successfully set up on this machine" do
          expect(FastlaneCI::Services.onboarding_service).to receive(:correct_setup?).and_return(true)

          post("/data/setup")

          expect(last_response.status).to eq(400)
          expect(json["message"]).to eq("fastlane.ci already set up, you can't overwrite the existing configuration")
          expect(json["key"]).to eq("Onboarding")
        end
      end

      describe "Invalid inputs" do
        before do
          expect(FastlaneCI::Services.onboarding_service).to receive(:correct_setup?).and_return(false)
        end

        it "Missing parameters" do
          post("/data/setup")

          expect(last_response.status).to eq(400)
          expect(json["message"]).to eq("Missing required parameters encryption_key, bot_token, bot_password, config_repo, initial_onboarding_token")
          expect(json["key"]).to eq("Onboarding.Parameter.Missing")
        end

        describe "Invalid API token format" do
          before do
            allow(FastlaneCI::GitHubService).to receive(:token_scope_validation_error).and_return(nil)
          end

          it "invalid bot token" do
            post("/data/setup", {
              encryption_key: "encryption_key",
              bot_account: {
                token: "invalid",
                password: "password"
              },
              config_repo: "https://github.com/fastlane/ci-config",
              initial_onboarding_token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            }.to_json)

            expect(last_response.status).to eq(400)
            expect(json["message"]).to eq("The GitHub token format is valid, they should be 40 characters long")
            expect(json["key"]).to eq("Onboarding.Token.Invalid")
          end

          it "invalid initial_onboarding_token" do
            post("/data/setup", {
              encryption_key: "encryption_key",
              bot_account: {
                token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                password: "password"
              },
              config_repo: "https://github.com/fastlane/ci-config",
              initial_onboarding_token: "invalid"
            }.to_json)

            expect(last_response.status).to eq(400)
            expect(json["message"]).to eq("The GitHub token format is valid, they should be 40 characters long")
            expect(json["key"]).to eq("Onboarding.Token.Invalid")
          end
        end

        describe "API token with missing permission scope" do
          it "returns the right error" do
            scope_validation_error = [[], "repo"]
            expect(FastlaneCI::GitHubService).to receive(:token_scope_validation_error).and_return(scope_validation_error)

            post("/data/setup", {
              encryption_key: "encryption_key",
              bot_account: {
                token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                password: "password"
              },
              config_repo: "https://github.com/fastlane/ci-config",
              initial_onboarding_token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            }.to_json)

            expect(last_response.status).to eq(400)
            expect(json["message"]).to eq("Token should include \"repo\" scope, currently it's in empty scope.")
            expect(json["key"]).to eq("Onboarding.Token.MissingScope")
          end
        end

        describe "Invalid ci-config repo URL" do
          before do
            allow(FastlaneCI::GitHubService).to receive(:token_scope_validation_error).and_return(nil)
          end

          it "returns an error if the URL doesn't start with https://" do
            post("/data/setup", {
              encryption_key: "encryption_key",
              bot_account: {
                token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                password: "password"
              },
              config_repo: "git://invalid.url",
              initial_onboarding_token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            }.to_json)

            expect_json_error(
              status: 400,
              message: "The config repo URL has to start with https://",
              key: "Onboarding.ConfigRepo.NoHTTPs"
            )
          end

          it "returns an error if the ci-config repo can't be cloned" do
            allow(FastlaneCI::Services).to receive(:reset_services!).and_return(nil) # we don't want this, as we stub all the things
            expect(FastlaneCI::Services.configuration_repository_service).to receive(:setup_private_configuration_repo).and_return(nil)
            class FastlaneCI::Launch
            end
            expect(FastlaneCI::Launch).to receive(:start_github_workers)
            expect(FastlaneCI::Services.onboarding_service).to receive(:clone_remote_repository_locally).and_raise("Failed to clone")

            keys_writer = "keys_writer"
            expect(keys_writer).to receive(:write!).and_return(nil).twice

            expected_parameters = {
              path: "#{ENV['HOME']}/.fastlane/ci/.keys",
              locals: {
                ci_base_url: FastlaneCI.dot_keys.ci_base_url,
                encryption_key: "encryption_key",
                ci_user_password: "password",
                ci_user_api_token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                repo_url: "https://github.com/fastlane/ci-config",
                initial_onboarding_user_api_token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
              }
            }

            allow(FastlaneCI::KeysWriter).to receive(:new).with(expected_parameters).and_return(keys_writer)

            post("/data/setup", {
              encryption_key: "encryption_key",
              bot_account: {
                token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                password: "password"
              },
              config_repo: "https://github.com/fastlane/ci-config",
              initial_onboarding_token: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            }.to_json)

            # Cloning the repo fails because we block the internet connection when running tests
            expect_json_error(
              status: 400,
              message: "Failed to clone the ci-config repo, please make sure the bot has access to it",
              key: "Onboarding.ConfigRepo.NoAccess"
            )
          end
        end
      end
    end
  end
end
