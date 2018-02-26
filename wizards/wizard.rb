module FastlaneCI
  # The `Wizard` uses the command design pattern to model how a wizard should
  # run. Concretions extending the Wizard must implement the `run!` method
  #
  # @abstract
  class Wizard
    # @abstract
    # @return [nil]
    def run!
      not_implemented(__method__)
    end
  end
end
