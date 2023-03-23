# Changelog

Matcha uses [Semantic Versioning 2.0.0](https://semver.org/).

Changes before `v0.2.0` are considered pre-release and not included here.

# Devlog 2023-03-24

A few updates:

## Enhancements

- Mirror OTP 25's support for `binary_part/2`, `binary_part/3`, `byte_size/1` in match specs
- Got support for `ceil/2`, `floor/3`, `is_function/2`, `tuple_size/1` in the [upcoming OTP 26](https://github.com/erlang/otp/pull/7046)'s release (:bangbang:)
  - added to `Matcha` for when it becomes available
  - this should mean all guard-safe functions are available in match specs for Elixir and Erlang
    - except `:erlang.is_record/2`, which Elixir has a work-around for
- Added documentation and cheatsheets for adopting `Matcha`

## Fixes

- Prevent Matcha from emitting warning when not using `:mnesia`
- Fix some issues with `and/2` and `or/2` when used in match spec bodies
