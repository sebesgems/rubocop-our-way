# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::OurWay::NoToFForMoney, :config do
  let(:config) do
    RuboCop::Config.new(
      'OurWay/NoToFForMoney' => {
        'Enabled' => true,
        'AllowedReceivers' => %w[Time Process]
      }
    )
  end

  it 'flags to_f on a variable' do
    expect_offense(<<~RUBY)
      amount.to_f
             ^^^^ Don't use `to_f` for money. Use `to_d` (BigDecimal) or cents as Integer.
    RUBY
  end

  it 'auto-corrects string literal to to_d' do
    expect_offense(<<~RUBY)
      "1.23".to_f
             ^^^^ Don't use `to_f` for money. Use `to_d` (BigDecimal) or cents as Integer.
    RUBY

    expect_correction(<<~RUBY)
      "1.23".to_d
    RUBY
  end

  it 'does not flag Time.now.to_f (allowed receiver)' do
    expect_no_offenses('Time.now.to_f')
  end

  it 'does not auto-correct non-literal receivers' do
    expect_offense(<<~RUBY)
      price.to_f
            ^^^^ Don't use `to_f` for money. Use `to_d` (BigDecimal) or cents as Integer.
    RUBY

    # For non-literals we only flag; no autocorrect is applied.
    expect_no_corrections
  end

  it 'does not flag Time.zone.now.to_f' do
    expect_no_offenses(<<~RUBY)
      Time.zone.now.to_f
    RUBY
  end
end
