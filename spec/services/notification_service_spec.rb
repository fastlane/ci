require_relative "../spec_helper.rb"
require File.expand_path("../../../shared/models/notification.rb", __FILE__)
require File.expand_path("../../../services/notification_service.rb", __FILE__)

describe FastlaneCI::NotificationService do
  let(:notification_service) { described_class.new }
  let(:file_path) { File.join(FastlaneCI::FastlaneApp.settings.root, "spec/fixtures/files") }

  before(:each) do
    stub_const("ENV", { "data_store_folder" => file_path })
    File.stub(:write)
  end

  describe "#create_notification!" do
    context "notification doesn't exist" do
      before(:each) do
        File.should_receive(:read)
            .with(File.join(file_path, "notifications.json"))
            .and_return("[]")
      end

      it "returns a new `Notification` if the notification does not exist" do
        expect(
          notification_service.create_notification!(notification_params)
        ).to be_an_instance_of(FastlaneCI::Notification)
      end

      it "writes to the `notifications.json` file" do
        File.should_receive(:write)
        notification_service.create_notification!(notification_params)
      end
    end

    context "notification exists" do
      before(:each) do
        File.should_receive(:read)
            .with(File.join(file_path, "notifications.json"))
            .and_return(json_notification_string)
      end

      it "returns `nil` if the notification already exists" do
        expect(
          notification_service.create_notification!(notification_params)
        ).to be_nil
      end

      it "doesn't write to the `notifications.json` file" do
        File.should_not_receive(:write)
        notification_service.create_notification!(notification_params)
      end
    end
  end

  describe "#update_notification!" do
    let(:notification) { FastlaneCI::Notification.new(new_notification_params) }

    context "notification doesn't exist" do
      before(:each) do
        File.should_receive(:read)
            .with(File.join(file_path, "notifications.json"))
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
            .with(File.join(file_path, "notifications.json"))
            .and_return(json_notification_string)
      end

      it "writes to the `notifications.json` file" do
        File.should_receive(:write)
        notification_service.update_notification!(notification: notification)
      end
    end
  end

  def json_notification_string
    <<~JSON
      [
        {
          "id": "66644e9e-17f4-4ba2-bdcb-4020c8b14479",
          "priority": "LOW",
          "name": "test_notif",
          "message": "this is a test notification",
          "created_at": "2018-02-16 13:44:08 -0500",
          "updated_at": "2018-02-16 13:44:08 -0500"
        }
      ]
    JSON
  end

  def notification_params
    {
      priority: "LOW",
      name: "test_notif",
      message: "this is a test notification"
    }
  end

  def new_notification_params
    {
      priority: "HIGH",
      name: "test_notif",
      message: "this is a test notification"
    }
  end
end

require "ripper"

# Monkey patch to fix issue with HEREDOC in rspec for Ruby 2.3
#
# https://github.com/rspec/rspec-core/issues/2163#issuecomment-193657248
Ripper::Lexer.class_eval do
  def on_heredoc_dedent(v, w)
    @buf.last.each do |e|
      next unless e.event == :on_tstring_content
      if (n = dedent_string(e.tok, w)) > 0
        e.pos[1] += n
      end
    end
    v
  end
end
