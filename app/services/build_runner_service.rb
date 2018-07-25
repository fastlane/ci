require_relative "../features/build_runner/fastlane_build_runner"

module FastlaneCI
  # Responsible for
  # - Manage all `TestRunner` objects that are active (either in queue or actually running)
  # - Provide helper methods to make it easy to find currently running/queued BuildRunners
  #
  # TODO: move github specific stuff out into GitHubService (GitHubService right now)
  # TODO: maybe rename this to GitHubBuildRunnerService
  class BuildRunnerService
    include FastlaneCI::Logging

    attr_accessor :build_runners

    def initialize
      self.build_runners = []
    end

    # @return TaskQueue::Task
    def add_build_runner(build_runner:)
      raise "No build runner provided" unless build_runner.respond_to?(:start)

      task = TaskQueue::Task.new(work_block: proc do
        build_runners << build_runner
        build_runner.start
      end)
      build_runner_task_queue.add_task_async(task: task)

      return task
    end

    def remove_build_runner(build_runner:)
      task = TaskQueue::Task.new(work_block: proc do
        build_runners.delete(build_runner)
      end)
      build_runner_task_queue.add_task_async(task: task)
    end

    def build_runner_task_queue
      @_build_runner_task_queue ||= TaskQueue::TaskQueue.new(name: "build runner service")
    end

    # Fetch all the active runners, and see if there is one WIP
    def find_build_runner(project_id:, sha: nil, build_number: nil)
      return build_runners.find do |build_runner|
        build_runner.project.id == project_id &&
        (build_runner.current_build.sha == sha || build_runner.current_build.number == build_number)
      end
    end
  end
end
