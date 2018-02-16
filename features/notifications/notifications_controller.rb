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
      Services.notification_service.create_notification!(notification_params)
      redirect HOME
    end

    post "#{HOME}/update" do
      Services.notification_service.update_notification!(notification_params)
      redirect HOME
    end

    private

    # Parameters used for creating and updating notifications
    #
    # @return [Hash]
    def notification_params
      {
        priority: params[:priority],
        name: params[:name],
        message: params[:message]
      }
    end
  end
end
