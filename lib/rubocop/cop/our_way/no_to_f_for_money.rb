# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Cop
    module OurWay
      # Forbids using `.to_f` for monetary values.
      #
      # Why: Floats are binary and cannot represent 0.01 exactly.
      # Use BigDecimal (`to_d`) or integer cents instead.
      #
      # Safe autocorrect: only for literal receivers (String/Integer/Float),
      # we turn `.to_f` into `.to_d`. We do NOT autocorrect arbitrary receivers.
      #
      # Configure via .rubocop.yml (or gem default):
      #   OurWay/NoToFForMoney:
      #     AllowedReceivers:
      #       - 'Time'        # allow Time.now.to_f
      #       - 'Process'     # allow Process.clock_gettime(...).to_f
      #
      class NoToFForMoney < ::RuboCop::Cop::Base
        extend ::RuboCop::Cop::AutoCorrector

        MSG = "Don't use `to_f` for money. Use `to_d` (BigDecimal) or cents as Integer."

        # (send <recv> :to_f)
        def_node_matcher :to_f_call?, <<~PATTERN
          (send $_ :to_f)
        PATTERN

        def on_send(node)
          recv = to_f_call?(node) or return
          return if allowed_receiver_chain?(recv)

          add_offense(node.loc.selector) do |corrector|
            corrector.replace(node.loc.selector, 'to_d') if literal_receiver?(recv)
          end
        end

        private

        def allowed_receiver_chain?(recv)
          return false if allowed_const_names.empty?

          base = leftmost_receiver(recv)
          base&.const_type? && allowed_const_names.include?(base.const_name)
        end

        def leftmost_receiver(node)
          n = node
          n = n.receiver while n&.send_type?
          n
        end

        def allowed_const_names
          @allowed_const_names ||= Array(cop_config['AllowedReceivers']).map!(&:to_s)
        end

        def literal_receiver?(recv)
          recv&.str_type? || recv&.float_type? || recv&.int_type?
        end
      end
    end
  end
end
