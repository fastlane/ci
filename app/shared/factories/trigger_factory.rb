# frozen_string_literal: true

require_relative "abstract_factory"

module FastlaneCI
  # TODO: Until we make a proper interface to attach JobTriggers to a Project, let's add a manual one for the
  # selected branch.
  # TODO: get default branch when there is no branch selected
  class TriggerFactory < AbstractFactory
    def create(params:)
      branch = params[:branch].nil? ? "master" : params[:branch]
      triggers_to_add = [FastlaneCI::ManualJobTrigger.new(branch: branch)]

      case params[:trigger_type]
      when FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit]
        triggers_to_add << FastlaneCI::CommitJobTrigger.new(branch: branch)
      when FastlaneCI::JobTrigger::TRIGGER_TYPE[:pull_request]
        triggers_to_add << FastlaneCI::PullRequestJobTrigger.new(branch: branch)
      when FastlaneCI::JobTrigger::TRIGGER_TYPE[:manual]
        # Nothing to do here, manual trigger is added by default
        logger.debug("Manual trigger selected - this is enabled by default")
      when FastlaneCI::JobTrigger::TRIGGER_TYPE[:nightly]
        triggers_to_add << FastlaneCI::NightlyJobTrigger.new(
          branch: branch,
          hour: params[:hour].to_i,
          minute: params[:minute].to_i
        )
      else
        raise "Couldn't create a JobTrigger"
      end

      return triggers_to_add
    end
  end
end
