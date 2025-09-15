
## Installation

First add this to your Gemfile:

```ruby
gem "rubocop-our-way", require: false, group: [ :development ], git: "https://github.com/sebesgems/rubocop-our-way"
```
```yml
# Require the gem first so that custom cop definitions gets loaded before applying cops from rubocop.yml
require:
  - rubocop-our-way

# Sebes Ruby styling for Rails
inherit_gem:
  rubocop-our-way: rubocop.yml
```
