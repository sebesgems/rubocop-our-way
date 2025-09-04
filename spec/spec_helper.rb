# frozen_string_literal: true

require 'bundler/setup'

# Load RuboCop once, first
require 'rubocop'
require 'rubocop/rspec/support'

require 'rubocop-our-way'

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense
end
