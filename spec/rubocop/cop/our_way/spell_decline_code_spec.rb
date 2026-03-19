# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::OurWay::SpellDeclineCode, :config do
  let(:config) do
    RuboCop::Config.new(
      'OurWay/SpellDeclineCode' => { 'Enabled' => true }
    )
  end

  context 'with a symbol key and allowed value' do
    it 'accepts a known decline code as a string' do
      expect_no_offenses(<<~RUBY)
        { spell_decline_code: "do_not_honour" }
      RUBY
    end

    it 'accepts a known decline code as a symbol' do
      expect_no_offenses(<<~RUBY)
        { spell_decline_code: :insufficient_funds }
      RUBY
    end

    it 'accepts a code that starts with a digit as a string' do
      expect_no_offenses(<<~RUBY)
        { spell_decline_code: "3ds_authentication_failed" }
      RUBY
    end
  end

  context 'with a string key and allowed value' do
    it 'accepts a known decline code as a string' do
      expect_no_offenses(<<~RUBY)
        { "spell_decline_code" => "expired_card" }
      RUBY
    end
  end

  context 'with a symbol key and disallowed value' do
    it 'flags an unknown decline code string' do
      expect_offense(<<~RUBY)
        { spell_decline_code: "made_up_code" }
                              ^^^^^^^^^^^^^^ `spell_decline_code` value "made_up_code" is not in the list of allowed decline codes.
      RUBY
    end

    it 'flags an unknown decline code symbol' do
      expect_offense(<<~RUBY)
        { spell_decline_code: :totally_wrong }
                              ^^^^^^^^^^^^^^ `spell_decline_code` value :totally_wrong is not in the list of allowed decline codes.
      RUBY
    end
  end

  context 'with a string key and disallowed value' do
    it 'flags an unknown decline code' do
      expect_offense(<<~RUBY)
        { "spell_decline_code" => "bad_code" }
                                  ^^^^^^^^^^ `spell_decline_code` value "bad_code" is not in the list of allowed decline codes.
      RUBY
    end
  end

  context 'with a dynamic value' do
    it 'ignores a variable (runtime validation is handled by spell-helpers)' do
      expect_no_offenses(<<~RUBY)
        { spell_decline_code: some_variable }
      RUBY
    end

    it 'ignores a method call (runtime validation is handled by spell-helpers)' do
      expect_no_offenses(<<~RUBY)
        { spell_decline_code: decline_code_for(payment) }
      RUBY
    end

    it 'ignores a hash lookup (runtime validation is handled by spell-helpers)' do
      expect_no_offenses(<<~RUBY)
        { spell_decline_code: response["error_code"] }
      RUBY
    end
  end

  context 'with an unrelated key' do
    it 'ignores other hash keys' do
      expect_no_offenses(<<~RUBY)
        { other_code: "made_up_code" }
      RUBY
    end
  end
end
