require File.expand_path("../../../spec_helper.rb", __FILE__)
require File.expand_path("../../../../shared/models/notification.rb", __FILE__)
require File.expand_path("../../../../services/notification_service.rb", __FILE__)
require File.expand_path("../../../../services/data_sources/json_notification_data_source.rb", __FILE__)

describe FastlaneCI::JSONNotificationDataSource do
  let(:file_path) do
    File.join(FastlaneCI::FastlaneApp.settings.root, "spec/fixtures/files/")
  end

  let (:notifications_file_path) do
    File.join(file_path, "notifications/notifications.json")
  end

  let(:notification_service) { described_class.create(file_path) }

  before(:each) do
    stub_git_repos
    stub_services
    stub_const("ENV", { "data_store_folder" => file_path })
    File.stub(:write)
  end

  describe "#create_notification!" do
    before(:each) do
      File.should_receive(:read)
          .with(notifications_file_path)
          .and_return("[]")
    end

    it "returns a new `Notification`" do
      expect(
        notification_service.create_notification!(notification_params)
      ).to be_an_instance_of(FastlaneCI::Notification)
    end

    it "writes to the `notifications.json` file" do
      File.should_receive(:write)
      notification_service.create_notification!(notification_params)
    end
  end

  describe "#update_notification!" do
    let(:notification) { FastlaneCI::Notification.new(new_notification_params) }

    context "notification doesn't exist" do
      before(:each) do
        File.should_receive(:read)
            .with(notifications_file_path)
            .and_return("[]")
      end

      it "raises an error message and doesn't write to the `notifications.json` file" do
        File.should_not_receive(:write)
        expect { notification_service.update_notification!(notification: notification) }.to raise_error
      end
    end

    context "notification exists" do
      before(:each) do
        File.should_receive(:read)
            .with(notifications_file_path)
            .and_return(json_notification_string)
      end

      it "writes to the `notifications.json` file" do
        File.should_receive(:write)
        notification_service.update_notification!(notification: notification)
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
      priority: "LOW",
      type: "acknowledgement_required",
      name: "test_notif",
      user_id: "some-user-id",
      message: "this is a test notification"
    }
  end

  def new_notification_params
    {
      id: "test-id",
      priority: "HIGH",
      type: "acknowledgement_required",
      user_id: "some-user-id",
      name: "test_notif",
      message: "this is a test notification"
    }
  end
end
