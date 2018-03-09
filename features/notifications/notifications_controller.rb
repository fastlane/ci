require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"
require "pathname"

module FastlaneCI
  # CRUD controller for handling and displaying notifications to user
  class NotificationsController < AuthenticatedControllerBase
    HOME = "/notifications"

    # Renders the notifications dashboard, displaying a table of notifications
    # scoped to the user
    get HOME do
      notifications = Services.notification_service.notification_data_source.notifications
      user_notifications = notifications.select { |notification| notification.user_id == user.id }
      locals = { notifications: user_notifications, title: "Notifications" }
      erb(:dashboard, locals: locals, layout: FastlaneCI.default_layout)
    end

    # Creates a new notification
    post "#{HOME}/create" do
      payload = notification_params(request)
      Services.notification_service.create_notification!(payload)
      redirect HOME
    end

    # Updates a notification with a given `name`
    post "#{HOME}/update" do
      notification = Notification.new(notification_params(request))
      Services.notification_service.update_notification!(notification: notification)
      redirect HOME
    end

    # Deletes a notification with a given `name`
    post "#{HOME}/delete/:id" do
      Services.notification_service.delete_notification!(id: params[:id])
      redirect HOME
    end

    private

    # Parameters used for creating and updating notifications:
    #   { :id, :priority, :type, :user_id, :name, :message }
    #
    # @param  [Sinatra::Request] request
    # @return [Hash]
    def notification_params(request)
      parse_request_body(request)
        .select { |k, _v| %i(id priority type user_id name message).include?(k) }
    end
  end
end
