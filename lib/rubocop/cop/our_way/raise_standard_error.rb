# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Cop
    module OurWay
      # Forbids raising `StandardError` directly.
      #
      # Why: `StandardError` is the base class most exceptions inherit from.
      # Raising it directly hides the real failure reason and makes it
      # impossible for callers to `rescue` the specific error without also
      # catching everything else.
      #
      # @example
      #   # bad
      #   raise StandardError
      #
      #   # bad
      #   raise StandardError, "something went wrong"
      #
      #   # bad
      #   raise StandardError.new("something went wrong")
      #
      #   # good
      #   raise ArgumentError, "something went wrong"
      #
      class RaiseStandardError < ::RuboCop::Cop::Base
        MSG = "Don't raise `StandardError` directly. Raise a specific error class instead."

        # Matches:
        #   raise StandardError
        #   raise StandardError, "msg"
        #   raise StandardError.new("msg")
        #   raise StandardError.exception("msg")
        def_node_matcher :raise_standard_error?, <<~PATTERN
          (send nil? {:raise :fail}
            {
              (const {nil? cbase} :StandardError)
              (send (const {nil? cbase} :StandardError) {:new :exception} ...)
            }
            ...)
        PATTERN

        def on_send(node)
          return unless raise_standard_error?(node)

          add_offense(node.first_argument)
        end
      end
    end
  end
end