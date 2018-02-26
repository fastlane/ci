require_relative "implementations/shell"
require_relative "interface"

module FastlaneCI
  # UI class with static helper methods for printing output in a formatted way.
  # Used by the project wizards
  class UI
    class << self
      # Returns a memoized reference to the Shell singleton
      #
      # @return [Shell]
      def current
        @current ||= Shell.new
      end
    end

    # Not using `responds` because we don't care about methods like .to_s and so on
    def self.method_missing(method_sym, *args, &_block)
      interface_methods = FastlaneCI::Interface.instance_methods - Object.instance_methods

      unless interface_methods.include?(method_sym)
        UI.user_error!("Unknown method '#{method_sym}', supported #{interface_methods}")
      end

      self.current.public_send(method_sym, *args)
    end
  end
end
