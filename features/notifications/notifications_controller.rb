require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"
require "pathname"

module FastlaneCI
  # CRUD controller for handling and displaying notifications to user
  class NotificationsController < AuthenticatedControllerBase
    HOME = "/notifications"

    # Renders the notifications dashboard, displaying a table of all notifications
    #
    # @return [nil]
    get HOME do
      notifications = Services.notification_service.notification_data_source.notifications
      locals = { notifications: notifications, title: "Notifications" }
      erb(:dashboard, locals: locals, layout: FastlaneCI.default_layout)
    end

    # Creates a new notification
    #
    # @return [nil]
    post "#{HOME}/create" do
      payload = notification_params(request)
      Services.notification_service.create_notification!(payload)
      redirect HOME
    end

    # Updates a notification with a given `name`
    #
    # @return [nil]
    post "#{HOME}/update" do
      notification = Notification.new(notification_params(request))
      Services.notification_service.update_notification!(notification: notification)
      redirect HOME
    end

    # Deletes a notification with a given `name`
    #
    # @return [nil]
    post "#{HOME}/delete/:name" do
      Services.notification_service.delete_notification!(name: params[:name])
      redirect HOME
    end

    private

    # Parses the JSON request body and returns a Ruby hash
    #
    # @param  [Sinatra::Request] request
    # @return [Hash]
    def parse_request_body(request)
      JSON.parse(request.body.read).symbolize_keys
    end

    # Parameters used for creating and updating notifications:
    #   { :priority, :name, :message }
    #
    # @param  [Sinatra::Request] request
    # @return [Hash]
    def notification_params(request)
      parse_request_body(request)
        .select { |k, _v| %i(priority name message).include?(k) }
    end
  end
end
