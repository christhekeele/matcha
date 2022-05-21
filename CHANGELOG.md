# Changelog

Matcha uses [Semantic Versioning 2.0.0](https://semver.org/).

## v0.2.0

- Completely reworks the `Matcha.Context` system.
- Adds support for `is_boolean/1` in match specs.
- Adds `Matcha.Spec.run!/2` and `Matcha.Spec.call!/2`.
- Drops support for Elixir v1.10.x, allowing for
  - Sigils in match specs.
  - `in/2` in match specs (for literal lists/ranges).
