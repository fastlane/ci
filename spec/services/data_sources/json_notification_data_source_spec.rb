require "spec_helper"
require "app/shared/models/notification"
require "app/services/data_sources/json_notification_data_source"

describe FastlaneCI::JSONNotificationDataSource do
  before(:each) do
    stub_file_io
    stub_git_repos
    stub_services
  end

  let(:file_path) do
    File.join(FastlaneCI::FastlaneApp.settings.root, "spec/fixtures/files/")
  end

  let (:notifications_file_path) do
    File.join(file_path, "notifications/notifications.json")
  end

  let(:json_notification_data_source) { described_class.create(file_path) }

  describe "#create_notification!" do
    before(:each) do
      expect(File).to receive(:read)
        .with(notifications_file_path)
        .and_return("[]")
    end

    it "returns a new `Notification`" do
      expect(
        json_notification_data_source.create_notification!(notification_params)
      ).to be_an_instance_of(FastlaneCI::Notification)
    end

    it "writes to the `notifications.json` file" do
      expect(File).to receive(:write)
      json_notification_data_source.create_notification!(notification_params)
    end
  end

  describe "#update_notification!" do
    let(:notification) { FastlaneCI::Notification.new(new_notification_params) }

    context "notification doesn't exist" do
      before(:each) do
        expect(File).to receive(:read)
          .with(notifications_file_path)
          .and_return("[]")
      end

      it "raises an error message and doesn't write to the `notifications.json` file" do
        expect(File).not_to(receive(:write))
        expect { json_notification_data_source.update_notification!(notification: notification) }.to raise_error(RuntimeError)
      end
    end

    context "notification exists" do
      before(:each) do
        expect(File).to receive(:read)
          .with(notifications_file_path)
          .and_return(json_notification_string)
      end

      it "writes to the `notifications.json` file" do
        expect(File).to receive(:write)
        json_notification_data_source.update_notification!(notification: notification)
      end
    end
  end

  def json_notification_string
    File.open(
      File.join(
        FastlaneCI::FastlaneApp.settings.root,
        "spec/fixtures/files/notifications/mock_notifications.json"
      )
    ).read
  end

  def notification_params
    {
      id: "test-id",
      priority: "urgent",
      type: "acknowledgement_required",
      name: "test_notif",
      user_id: "some-user-id",
      message: "this is a test notification"
    }
  end

  def new_notification_params
    {
      id: "test-id",
      priority: "success",
      type: "acknowledgement_required",
      user_id: "some-user-id",
      name: "test_notif",
      message: "this is a test notification"
    }
  end
end
