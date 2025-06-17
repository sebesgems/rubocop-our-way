Gem::Specification.new do |s|
  s.required_ruby_version = '>= 3.3'

  s.name = 'rubocop-our-way'
  s.authors = ['Sebes Technology ltd']

  s.summary = 'Store all repetitive integration logic'

  s.version = '1.0.3'

  s.platform = Gem::Platform::RUBY

  s.add_dependency 'rubocop', '>= 1.74'
  s.add_dependency 'rubocop-rails', '>= 2.30'

  s.files = %w[rubocop.yml]
end
