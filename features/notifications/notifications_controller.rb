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
      locals = { notifications: user_notifications, title: "Notifications" }
      erb(:dashboard, locals: locals, layout: FastlaneCI.default_layout)
    end

    private

    # @return [Array[Notification]]
    def user_notifications
      return Services.notification_service
                     .notifications
                     .select { |notification| notification.user_id == user.id }
    end
  end
end
