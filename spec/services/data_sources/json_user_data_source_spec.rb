require "spec_helper"
require "app/shared/models/user"
require "app/services/data_sources/json_user_data_source"

describe FastlaneCI::JSONUserDataSource do
  before(:each) do
    stub_file_io
    stub_git_repos
    stub_services
    stub_environment_variables
  end

  let(:file_path) do
    File.join(FastlaneCI::FastlaneApp.settings.root, "spec/fixtures/files/")
  end

  let (:users_file_path) do
    File.join(file_path, "users/users.json")
  end

  subject { described_class.create(file_path) }

  describe "#update_user!" do
    let(:user) { users.first }
    let(:users) { user_params.map { |params| FastlaneCI::User.new(params) } }

    context "user doesn't exist" do
      before(:each) do
        subject.stub(:users).and_return([])
      end

      it "raises an error message and doesn't write to the `users.json` file" do
        expect(File).not_to(receive(:write))
        expect { subject.update_user!(user: user) }.to raise_error
      end
    end

    context "user exists" do
      let(:new_user_email) { "new.user1@gmail.com" }
      let(:new_user) { FastlaneCI::User.new(user_params.first.merge(email: new_user_email)) }

      before(:each) do
        subject.stub(:users).and_return(users)
      end

      it "updates the `user` email in the `users.json` file" do
        expect { subject.update_user!(user: new_user) }
          .to change { subject.users.first.email }.from(first_user_email).to(new_user_email)
      end

      it "returns `true` when a user is updated" do
        expect(subject.update_user!(user: new_user)).to be(true)
      end
    end
  end

  describe "#delete_user!" do
    let(:user) { users.first }
    let(:users) { user_params.map { |params| FastlaneCI::User.new(params) } }

    context "user doesn't exist" do
      before(:each) do
        subject.stub(:users).and_return([])
      end

      it "raises an error message and doesn't write to the `users.json` file" do
        expect(File).not_to(receive(:write))
        expect { subject.delete_user!(user: user) }.to raise_error
      end
    end

    context "user exists" do
      before(:each) do
        subject.stub(:users).and_return(users)
      end

      it "removes the `user` from the `users.json` file" do
        expect { subject.delete_user!(user: user) }.to change { subject.users.size }.from(2).to(1)
      end

      it "returns `true` when a user is deleted" do
        expect(subject.delete_user!(user: user)).to be(true)
      end
    end
  end

  private

  def first_user_email
    "test.user1@gmail.com"
  end

  def user_params
    [
      {
        id: "uuid-1",
        email: first_user_email,
        password_hash: "some-bad-password",
        provider_credentials: [
          FastlaneCI::GitHubProviderCredential.new(
            id: "uuid-2",
            email: "provider.email@gmail.com",
            full_name: "Clone user credentials",
            api_token: "some-bad-api-token"
          )
        ]
      },
      {
        id: "uuid-3",
        email: "test.user2@gmail.com",
        password_hash: "another-bad-password",
        provider_credentials: []
      }
    ]
  end
end
