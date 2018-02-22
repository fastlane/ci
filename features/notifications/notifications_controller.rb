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
    # @return [nil]
    def initialize(app = nil)
      @task_queue = TaskQueue::TaskQueue.new(name: "notifications")
      super(app)
    end

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
      add_to_task_queue do
        payload = notification_params(request)
        Services.notification_service.create_notification!(payload)
      end

      redirect HOME
    end

    # Updates a notification with a given `name`
    #
    # @return [nil]
    post "#{HOME}/update" do
      add_to_task_queue do
        notification = Notification.new(notification_params(request))
        Services.notification_service.update_notification!(notification: notification)
      end

      redirect HOME
    end

    # Deletes a notification with a given `name`
    #
    # @return [nil]
    post "#{HOME}/delete/:name" do
      add_to_task_queue { Services.notification_service.delete_notification!(name: params[:name]) }
      redirect HOME
    end

    private

    # Adds a block of code to the notifications task queue
    #
    # @param  [Proc] block
    # @return [nil]
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
