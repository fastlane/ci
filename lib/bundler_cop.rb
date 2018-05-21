# frozen_string_literal: true

module RuboCop
  module Cop
    module Bundler
      ##
      # discourage usage of pessimistic version locking
      #
      # discussed here: https://github.com/fastlane/ci/pull/905
      class PessimisticVersionMatcher < Cop
        MSG = "Please use `<` and `>=` instead of `~>`."

        def_node_matcher :pessimistic_lock?, <<-PATTERN
          (send nil? :gem _ (str $#pessimistic_lock_string?) ...)
        PATTERN

        def pessimistic_lock_string?(version_string)
          version_string.start_with?("~>")
        end

        def on_send(node)
          pessimistic_lock?(node) do |source|
            message = format(MSG, source: source)

            add_offense(
              node,
              message: message
            )
          end
        end
      end
    end
  end
end
