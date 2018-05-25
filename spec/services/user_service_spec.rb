require "spec_helper"
require "app/services/user_service"

describe FastlaneCI::UserService do
  let(:user_id) { "user_id" }

  let(:credentials) do
    (1..3).map do |index|
      FastlaneCI::GitHubProviderCredential.new(
        provider_credential_params.merge(id: index.to_s)
      )
    end
  end

  let(:user) do
    FastlaneCI::User.new(
      id: user_id,
      email: "email",
      password_hash: "password_hash",
      provider_credentials: credentials
    )
  end

  subject do
    FastlaneCI::UserService.new(
      user_data_source: FastlaneCI::JSONUserDataSource.create(git_repo_path)
    )
  end

  before(:each) do
    stub_const("ENV", { "FASTLANE_CI_ENCRYPTION_KEY" => "key" })
    stub_file_io
    stub_git_repos
    stub_services
  end

  describe "#create_provider_credential!" do
    let(:new_id) { "4" }

    let(:new_credential) do
      FastlaneCI::GitHubProviderCredential.new(provider_credential_params.merge(id: new_id))
    end

    # :user, updated with an extra provider credential
    let(:updated_user) do
      FastlaneCI::User.new(
        id: user.id,
        email: user.email,
        password_hash: user.password_hash,
        provider_credentials: user.provider_credentials.push(new_credential)
      )
    end

    context "user exists" do
      before(:each) do
        allow(subject).to receive(:find_user).with(id: user_id) { user }
        allow(subject).to receive(:update_user!).with(user: updated_user)
      end

      # TODO: Need to rethink how to accomplish this now that we're not returning exactly the same object,
      # but rather a new instance of the same object with the updated values
      # #Functional
      # it "creates a new provider credential for the user" do
      #   expect(FastlaneCI::User).to receive(:new).with(
      #     id: updated_user.id,
      #     email: updated_user.email,
      #     password_hash: updated_user.password_hash,
      #     provider_credentials: updated_user.provider_credentials
      #   ).and_return(updated_user)

      #   subject.create_provider_credential!(
      #     provider_credential_params.merge(user_id: user_id, id: new_id)
      #   )
      # end
    end
  end

  describe "#update_provider_credential!" do
    let(:id_to_update) { "2" }
    let(:changed_name) { "changed_name" }

    let(:new_credential) do
      FastlaneCI::GitHubProviderCredential.new(
        provider_credential_params.merge(id: id_to_update, full_name: changed_name)
      )
    end

    let(:updated_user) do
      FastlaneCI::User.new(
        id: user.id,
        email: user.email,
        password_hash: user.password_hash,
        provider_credentials: user.provider_credentials
          .delete_if { |credential| credential.id == id_to_update }
          .push(new_credential)
      )
    end

    context "user exists" do
      before(:each) do
        allow(subject).to receive(:find_user).with(id: user_id) { user }
        allow(subject).to receive(:update_user!).with(user: updated_user)
      end

      it "replaces provider credential for the user" do
        expect(FastlaneCI::User).to receive(:new).with(
          id: updated_user.id,
          email: updated_user.email,
          password_hash: updated_user.password_hash,
          provider_credentials: updated_user.provider_credentials
        ).and_return(updated_user)

        subject.update_provider_credential!(
          provider_credential_params.merge(
            user_id: user_id, id: id_to_update, full_name: changed_name
          )
        )
      end
    end
  end

  def provider_credential_params
    {
      email: "fake_email@gmail.com",
      api_token: "fake_api_token",
      full_name: "full_name"
    }
  end
end
