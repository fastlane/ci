require "forwardable"
require "micromachine"
require_relative "../agent"

module FastlaneCI::Agent
  ##
  # StateMachine defines the state and transition events of an Invocation
  #
  # This module is implemented to be `prepended` into a class.
  #
  # Methods for each transition are defined, and will only be called in the containing class
  # if the transition is valid.
  #
  # On every transition `send_state` will be attempted to be called.
  module StateMachine
    include Logging
    extend Forwardable

    # forward methods to the state machine
    def_delegators :state_machine, :state, :events, :states

    def state_machine
      @state_machine ||= MicroMachine.new("pending").tap do |fsm|
        fsm.when(:run,     "pending"   => "running")
        fsm.when(:finish,  "running"   => "finishing")
        fsm.when(:succeed, "finishing" => "succeeded")
        fsm.when(:reject,  "pending"   => "rejected",
                           "running"   => "rejected")
        fsm.when(:fail,    "running"   => "failed")
        fsm.when(:throw,   "pending"   => "broken",
                           "running"   => "broken",
                           "finishing" => "broken")

        # send update whenever we transition states.
        fsm.on(:any) do |event, payload|
          send_state(event, payload)
        end
      end
    end

    def send_state(event, payload)
      logger.debug("Event `#{event}` causing state change to #{state}. #{payload}")
      super
    end

    def run
      unless state_machine.trigger(:run)
        valid = state_machine.triggerable_events.inspect
        logger.error("`run` could not transition from `#{state}`. #{valid} are the only valid events.")
        return
      end

      super
    end

    def finish
      unless state_machine.trigger(:finish)
        valid = state_machine.triggerable_events.inspect
        logger.error("`finish` could not transition from `#{state}`. #{valid} are the only valid events.")
        return
      end

      super
    end

    def succeed
      unless state_machine.trigger(:succeed)
        valid = state_machine.triggerable_events.inspect
        logger.error("`succeed` could not transition from `#{state}`. #{valid} are the only valid events.")
        return
      end

      super
    end

    def reject(exception)
      unless state_machine.trigger(:reject, exception)
        valid = state_machine.triggerable_events.inspect
        logger.error("`reject` could not transition from `#{state}`. #{valid} are the only valid events.")
        return
      end

      super
    end

    def fail
      unless state_machine.trigger(:fail)
        valid = state_machine.triggerable_events.inspect
        logger.error("`fail` could not transition from `#{state}`. #{valid} are the only valid events.")
        return
      end

      super
    end

    def throw(exception)
      unless state_machine.trigger(:throw, exception)
        valid = state_machine.triggerable_events.inspect
        logger.error("`throw` could not transition from `#{state}`. #{valid} are the only valid events.")
        return
      end

      super
    end
  end
end
