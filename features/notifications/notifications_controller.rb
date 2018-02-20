require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"
require "pathname"

module FastlaneCI
  # Controller for handling and displaying notifications to user
  class NotificationsController < AuthenticatedControllerBase
    HOME = "/notifications"

    get HOME do
      notifications = Services.notification_service.notification_data_source.notifications

      locals = {
        notifications: notifications,
        title: "Notifications"
      }
      erb(:dashboard, locals: locals, layout: FastlaneCI.default_layout)
    end

    post "#{HOME}/create" do
      payload = notification_params(request)
      Services.notification_service.create_notification!(payload)
      redirect HOME
    end

    post "#{HOME}/update" do
      notification = Notification.new(notification_params(request))
      Services.notification_service.update_notification!(notification: notification)
      redirect HOME
    end

    private

    # Parameters used for creating and updating notifications:
    #   { :priority, :name, :message }
    #
    # @param  [String]
    # @return [Hash]
    def notification_params(request)
      JSON.parse(request.body.read).symbolize_keys
    end
  end
end
