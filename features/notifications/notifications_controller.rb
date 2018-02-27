require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"
require_relative "../../taskqueue/task_queue"
require "pathname"

module FastlaneCI
  # CRUD controller for handling and displaying notifications to user
  class NotificationsController < AuthenticatedControllerBase
    HOME = "/notifications"

    # Instantiates a new `Notification Controller` with a task queue to process
    # requests
    #
    # @param  [Sinatra::Base] app
    def initialize(app = nil)
      super(app)
      @task_queue = TaskQueue::TaskQueue.new(name: "notifications")
    end

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
      add_to_task_queue do
        payload = notification_params(request)
        Services.notification_service.create_notification!(payload)
      end

      redirect HOME
    end

    # Updates a notification with a given `name`
    post "#{HOME}/update" do
      add_to_task_queue do
        notification = Notification.new(notification_params(request))
        Services.notification_service.update_notification!(notification: notification)
      end

      redirect HOME
    end

    # Deletes a notification with a given `name`
    post "#{HOME}/delete/:id" do
      Services.notification_service.delete_notification!(id: params[:id])
      redirect HOME
    end

    private

    # Adds a block of code to the notifications task queue
    #
    # @param  [Proc] block
    def add_to_task_queue(&block)
      task = TaskQueue::Task.new(work_block: proc { yield })
      @task_queue.add_task_async(task: task)
    end

    # Parses the JSON request body and returns a Ruby hash
    #
    # @param  [Sinatra::Request] request
    # @return [Hash]
    def parse_request_body(request)
      JSON.parse(request.body.read).symbolize_keys
    end

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
