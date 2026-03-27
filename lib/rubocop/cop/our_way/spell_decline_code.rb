# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Cop
    module OurWay
      # Ensures `spell_decline_code` is assigned only an allowed value.
      #
      # The Sebes Spell Connections API accepts a fixed set of decline codes.
      # Passing an unrecognised value will be silently ignored by the gateway,
      # which leads to hard-to-debug payment flow issues.
      #
      # Valid values are sourced from:
      #   Connections API → <Payment URL> → Decline → Schema → spell_decline_code
      #   https://gate.sebestech.com/wizard/api/#/Connections%20API/connections_api_payment
      #
      # To add new codes, update ALLOWED_CODES in this file.
      #
      # @example
      #   # bad
      #   params.merge(spell_decline_code: "unknown_code")
      #
      #   # bad
      #   { spell_decline_code: :something_made_up }
      #
      #   # good
      #   { spell_decline_code: "do_not_honour" }
      #
      #   # good – dynamic value, validated at runtime by spell-helpers
      #   { spell_decline_code: some_variable }
      #
      class SpellDeclineCode < ::RuboCop::Cop::Base
        MSG = '`spell_decline_code` value %<value>s is not in the list of allowed decline codes.'

        # Full list from Connections API → <Payment URL> → Decline → Schema → spell_decline_code
        ALLOWED_CODES = %w[
          unknown_payment_method
          invalid_card_number
          invalid_expires
          no_matching_terminal
          blacklisted_tx
          timeout_3ds_enrollment_check
          timeout_acquirer_status_check
          validation_card_details_missing
          validation_cvc_not_provided
          validation_cardholder_name_not_provided
          validation_card_number_not_provided
          validation_expires_not_provided
          validation_cvc_too_long
          validation_cardholder_name_too_long
          validation_card_number_too_long
          validation_expires_too_long
          3ds_authentication_failed
          validation_cvc_invalid
          validation_cardholder_name_invalid
          validation_card_number_invalid
          validation_expires_invalid
          acquirer_connection_error
          blacklisted_tx_issuing_country
          s2s_not_supported
          timeout
          general_transaction_error
          antifraud_general
          acquirer_internal_error
          exceeds_frequency_limit
          insufficient_funds
          purchase_already_paid_for
          issuer_not_available
          do_not_honour
          exceeds_withdrawal_limit
          exceeded_account_limit
          expired_card
          blacklisted_tx_risk_score
          transaction_not_supported_or_not_valid_for_card
          exceeded_acquirer_refund_amount
          transaction_not_permitted_on_terminal
          acquirer_configuration_error
          transaction_not_permitted_to_cardholder
          invalid_issuer_number
          restricted_card
          merchant_response_timeout
          reconcile_error
          lost_card
          stolen_card
          invalid_amount
          re_enter_transaction
          security_violation
          partial_forbidden
          suspected_fraud
          acquirer_routing_error
          payment_rejected_other_reason
          authorization_failed
          acquirer_error_cs
          decline_irregular_transaction_pattern
          invalid_card_data
          exceeded_terminal_limit
          recurring_token_expired
          soft_decline_contact_support
          payment_method_details_missing
          validation_phone_invalid
          validation_address_invalid
          validation_email_invalid
          validation_email_not_provided
          validation_email_too_long
          user_cancelled
          payment_expired
        ].freeze

        # Match both `spell_decline_code: value` and `"spell_decline_code" => value`
        def_node_matcher :spell_decline_code_pair?, <<~PATTERN
          (pair {(sym :spell_decline_code) (str "spell_decline_code")} $_)
        PATTERN

        def on_pair(node)
          value_node = spell_decline_code_pair?(node)
          return unless value_node
          return unless value_node.str_type? || value_node.sym_type?

          return if ALLOWED_CODES.include?(value_node.value.to_s)

          add_offense(value_node, message: format(MSG, value: value_node.source))
        end
      end
    end
  end
end
