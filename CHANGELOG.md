# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0]

### Added
- `OurWay/SpellDeclineCode` cop to enforce that `spell_decline_code` hash values are limited to the allowed set defined by the Sebes Spell Connections API
  - Checks both symbol keys (`spell_decline_code:`) and string keys (`"spell_decline_code" =>`)
  - Checks both string and symbol literal values; dynamic values are not checked
  - Allowed codes are configurable via `AllowedCodes` in `.rubocop.yml`

## [1.4.0]

### Added
- `OurWay/SpellControllerInheritance` cop to enforce inheritance from `Sebes::SpellController` for controllers in spell scope
  - Detects spell controllers via file path (`/spell/` directory)
  - Detects spell controllers via module namespace (`Spell` module)
  - Detects spell controllers via routes file (`scope path: :spell`)
  - Supports inheritance chain validation within same file
  - Supports cross-file inheritance chain validation (including engine and main app lookups)
  - Accepts shorthand `SpellController` reference when in `Sebes` namespace
  - Works with both main app and engine controllers

### Changed
- Enhanced `OurWay/SpellControllerInheritance` to support intermediate base classes
  - Controllers can now inherit from intermediate classes like `Api::SebesAbstractController` if those classes ultimately inherit from `Sebes::SpellController`
  - The cop recursively checks inheritance chains across files

## [0.1.0] - Initial Release

### Added
- `OurWay/NoToFForMoney` cop to prevent `.to_f` calls on Money objects
- Base cop infrastructure
- RuboCop configuration inheritance
