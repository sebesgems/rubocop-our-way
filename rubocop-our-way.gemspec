Gem::Specification.new do |s|
  spec.required_ruby_version = ">= 3.3"

  spec.name = "sebes"
  spec.authors = ["Sebes Technology ltd"]

  spec.summary = "Store all repetitive integration logic"

  s.version = "1.0.0"

  s.platform = Gem::Platform::RUBY

  s.add_dependency "rubocop", ">= 1.74"
  s.add_dependency "rubocop-rails", ">= 2.30"

  s.files = %w[ rubocop.yml ]
end
