# frozen_string_literal: true

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 3.3'

  s.name = 'rubocop-our-way'
  s.authors = ['Sebes Technology ltd']

  s.summary = 'Store all repetitive integration logic'
  s.description = 'Company-wide RuboCop defaults and custom cops (e.g., money safety).'

  s.version = '1.2.0'

  s.platform = Gem::Platform::RUBY

  s.add_dependency 'rubocop', '>= 1.74'
  s.add_dependency 'rubocop-rails', '>= 2.30'

  s.require_paths = ['lib']
  s.files = Dir[
    'lib/**/*.rb',
    'rubocop.yml'
  ]

  s.metadata['rubygems_mfa_required'] = 'true'
end
