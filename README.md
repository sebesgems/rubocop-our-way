# RuboCop Our Way

Custom RuboCop cops for Sebes projects.

## Installation

First add this to your Gemfile:

```ruby
gem "rubocop-our-way", require: false, group: [ :development ], git: "https://github.com/sebesgems/rubocop-our-way"
```

Then add to your `.rubocop.yml`:

```yml
# Require the gem first so that custom cop definitions gets loaded before applying cops from rubocop.yml
require:
  - rubocop-our-way

# Sebes Ruby styling for Rails
inherit_gem:
  rubocop-our-way: rubocop.yml
```

## Cops

### OurWay/SpellControllerInheritance

Ensures that controllers under the spell scope inherit from `Sebes::SpellController` instead of `ApplicationController` or other base controllers.

Controllers are identified as being in the spell scope by:
- File path containing `/spell/` directory
- Controller class being in a `Spell` module namespace
- Controller being routed under `scope path: :spell` in routes files

The cop supports:
- Direct inheritance checking
- Inheritance chain validation (including cross-file lookups)
- Engine controllers (checks both engine and main app paths)
- Shorthand references (`SpellController` when in `Sebes` namespace)

#### Examples

```ruby
# bad - in spell directory or scope
class TokensController < ApplicationController
end

# bad - in Spell module namespace
module Spell
  class TokensController < ApplicationController
  end
end

# bad - routed under spell scope
# config/routes.rb has: scope path: :spell do
class Blik::PurchasesController < ActionController::Base
end

# good
class TokensController < Sebes::SpellController
end

# good
module Spell
  class TokensController < Sebes::SpellController
  end
end

# good - shorthand when in Sebes namespace
module Sebes
  module Spell
    class TokensController < SpellController
    end
  end
end

# good - inherits through intermediate class
class Api::SebesAbstractController < Sebes::SpellController
end

class Blik::PurchasesController < Api::SebesAbstractController
end
```

### OurWay/SpellDeclineCode

Ensures `spell_decline_code` hash values are limited to the set of codes accepted by the Sebes Spell Connections API. Passing an unrecognised value is silently ignored by the gateway, causing hard-to-debug payment flow issues.

Only static string and symbol values are checked; dynamic values (variables, method calls) are skipped since they cannot be verified at parse time.

The full list of allowed codes is defined in `ALLOWED_CODES` inside the cop file. To add a new code, update that constant.

#### Examples

```ruby
# bad
{ spell_decline_code: "made_up_code" }

# bad
params.merge(spell_decline_code: :something_wrong)

# good
{ spell_decline_code: "do_not_honour" }

# good – dynamic value, validated at runtime by spell-helpers
{ spell_decline_code: response["error_code"] }
```

### OurWay/NoToFForMoney

Prevents calling `.to_f` on Money objects to avoid precision loss.

#### Examples

```ruby
# bad
money.to_f

# good
money.to_d
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests.

## Contributing

Bug reports and pull requests are welcome.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
