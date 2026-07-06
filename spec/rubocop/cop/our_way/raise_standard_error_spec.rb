# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::OurWay::RaiseStandardError, :config do
  let(:config) do
    RuboCop::Config.new(
      'OurWay/RaiseStandardError' => {
        'Enabled' => true
      }
    )
  end

  it 'flags a bare raise StandardError' do
    expect_offense(<<~RUBY)
      raise StandardError
            ^^^^^^^^^^^^^ Don't raise `StandardError` directly. Raise a specific error class instead.
    RUBY
  end

  it 'flags raise StandardError with a message' do
    expect_offense(<<~RUBY)
      raise StandardError, "boom"
            ^^^^^^^^^^^^^ Don't raise `StandardError` directly. Raise a specific error class instead.
    RUBY
  end

  it 'flags raise StandardError.new with a message' do
    expect_offense(<<~RUBY)
      raise StandardError.new("boom")
            ^^^^^^^^^^^^^^^^^^^^^^^^^ Don't raise `StandardError` directly. Raise a specific error class instead.
    RUBY
  end

  it 'flags raise StandardError.exception with a message' do
    expect_offense(<<~RUBY)
      raise StandardError.exception("boom")
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't raise `StandardError` directly. Raise a specific error class instead.
    RUBY
  end

  it 'flags fail StandardError' do
    expect_offense(<<~RUBY)
      fail StandardError, "boom"
           ^^^^^^^^^^^^^ Don't raise `StandardError` directly. Raise a specific error class instead.
    RUBY
  end

  it 'flags ::StandardError with a top-level cbase' do
    expect_offense(<<~RUBY)
      raise ::StandardError, "boom"
            ^^^^^^^^^^^^^^^ Don't raise `StandardError` directly. Raise a specific error class instead.
    RUBY
  end

  it 'does not flag a specific error class' do
    expect_no_offenses(<<~RUBY)
      raise ArgumentError, "boom"
    RUBY
  end

  it 'does not flag re-raising a rescued exception' do
    expect_no_offenses(<<~RUBY)
      begin
        do_something
      rescue StandardError => e
        raise e
      end
    RUBY
  end

  it 'does not flag rescuing StandardError (handled by Style/RescueStandardError)' do
    expect_no_offenses(<<~RUBY)
      begin
        do_something
      rescue StandardError => e
        handle(e)
      end
    RUBY
  end
end