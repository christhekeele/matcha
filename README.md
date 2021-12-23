# 🍵 Matcha

<!-- MODULEDOC BLURB -->

> **_First-class match specification tooling for Elixir._**

<!-- MODULEDOC BLURB -->

[![Version][hex-pm-version-badge]][hex-pm-versions]
[![Downloads][hex-pm-downloads-badge]][hex-pm-package]
[![Documentation][docs-badge]][docs]
[![Dependencies][deps-badge]][deps]
[![License][hex-pm-license-badge]][hex-pm-package]

|         👍         |                  [Test Suite][suite]                  |                   [Test Coverage][coverage]                    |
| :----------------: | :---------------------------------------------------: | :------------------------------------------------------------: |
| [Release][release] | [![Build Status][release-suite-badge]][release-suite] | [![Coverage Status][release-coverage-badge]][release-coverage] |
|  [Latest][latest]  |  [![Build Status][latest-suite-badge]][latest-suite]  |  [![Coverage Status][latest-coverage-badge]][latest-coverage]  |

#### Installation

`Matcha` is distributed via [hex.pm][hex-pm], you can install it with your dependency manager of choice using the config provided on its [hex.pm package][hex-pm-package] listing.

#### Documentation

Complete documentation including guides are hosted online on [hexdocs.pm][docs].

## Usage

### Synopsis

<!-- MODULEDOC SNIPPET -->
<!--
  all hyperlinks in this snippet must be inline,
  rather than using markdown link references
-->

`Matcha` offers tight integration with Elixir and match specifications.

Match specifications are a BEAM VM feature that executes **_simple_** pattern matching operations very close-to-the-metal, _often several thousand times more performant than a comparable `Enum` operation_. They can be used to efficiently:

- [filter/map in-memory data](https://www.erlang.org/doc/man/ets.html#match_spec_run-2)
- [find ETS objects](https://erlang.org/doc/man/ets.html#select-2)
- [trace specific function calls](https://erlang.org/doc/man/dbg.html#tp-2)

However, they are notoriously difficult to compose and use. Matcha makes this intuitive with ergonomic macros to compose them, and a high-level API with which to use them.

### Examples

```elixir
require Matcha

# Turn Elixir code into a match specification,
#  then use it to filter/map some data
iex> Matcha.spec do
...>   {x, y, z} -> x + y + z
...> end
...> |> Matcha.Spec.run([
...>   {1, 2, 3},
...>   {1, 2},
...>   {1, 2, 3, 4},
...>   {4, 5, 6}
...> ])
[6, 15]
```

For more information, check out [the interactive usage guides](https://hexdocs.pm/matcha/usage.html#content), including using Matcha for:

- [filtering & mapping data](https://hexdocs.pm/matcha/usage/filtering-and-mapping.html#content)
- [selecting objects from tables](https://hexdocs.pm/matcha/usage/tables.html#content)
- [tracing function calls](https://hexdocs.pm/matcha/usage/tracing.html#content)

<!-- MODULEDOC SNIPPET -->

## Support

Matcha strives to support all maintained combinations of Elixir and erlang/OTP. The canonical list of supported combinations is available by checking the latest successful [test matrix run][test-matrix], but boils down to:

- Elixir 1.10.x
  - OTP 22.x
- Elixir 1.11.x
  - OTP 22.x
  - OTP 23.x
  - OTP 24.x
- Elixir 1.12.x
  - OTP 22.x
  - OTP 23.x
  - OTP 24.x
- Elixir 1.13.x
  - OTP 22.x
  - OTP 23.x
  - OTP 24.x

Since it pokes around in compiler internals, it is important to get ahead of upcoming changes to the language.
This is accomplished with [nightly builds][test-edge] against the latest versions of Elixir, erlang/OTP, and dependencies;
which catches issues like [internal compiler function signature changes](https://github.com/christhekeele/matcha/commit/27f3f34284349d807fcd2817a04cb4628498a7eb#diff-daf93cf4dc6034e9862d0d844c783586210ea822ae6ded51d925b0ac9e09766bR31-R43).

## Contributing

Contributions are welcome! Check out the [contributing guide][contributing] for more information, and suggestions on where to start.

<!-- LINKS & IMAGES -->

<!-- Hex -->

[hex-pm]: https://hex.pm
[hex-pm-package]: https://hex.pm/packages/matcha
[hex-pm-versions]: https://hex.pm/packages/matcha/versions
[hex-pm-version-badge]: https://img.shields.io/hexpm/v/matcha.svg?maxAge=86400&style=flat-square
[hex-pm-downloads-badge]: https://img.shields.io/hexpm/dt/matcha.svg?maxAge=86400&style=flat-square
[hex-pm-license-badge]: https://img.shields.io/badge/license-MIT-7D26CD.svg?maxAge=86400&style=flat-square

<!-- Docs -->

[docs]: https://hexdocs.pm/matcha/index.html
[docs-guides]: https://hexdocs.pm/matcha/usage.html#content
[docs-badge]: https://img.shields.io/badge/documentation-online-purple?maxAge=86400&style=flat-square

<!-- Deps -->

[deps]: https://hex.pm/packages/matcha
[deps-badge]: https://img.shields.io/badge/dependencies-1-blue?maxAge=86400&style=flat-square

<!-- Status -->

[suite]: https://github.com/christhekeele/matcha/actions?query=workflow%3A%22Test+Suite%22
[coverage]: https://coveralls.io/github/christhekeele/matcha

<!-- Release Status -->

[release]: https://github.com/christhekeele/matcha/tree/release
[release-suite]: https://github.com/christhekeele/matcha/actions?query=workflow%3A%22Test+Suite%22+branch%3Arelease
[release-suite-badge]: https://img.shields.io/github/checks-status/christhekeele/matcha/release.svg?maxAge=86400&style=flat-square
[release-coverage]: https://coveralls.io/github/christhekeele/matcha?branch=release
[release-coverage-badge]: https://img.shields.io/coveralls/christhekeele/matcha/release.svg?maxAge=86400&style=flat-square

<!-- Latest Status -->

[latest]: https://github.com/christhekeele/matcha/tree/latest
[latest-suite]: https://github.com/christhekeele/matcha/actions?query=workflow%3A%22Test+Suite%22+branch%3Alatest
[latest-suite-badge]: https://img.shields.io/github/checks-status/christhekeele/matcha/latest.svg?maxAge=86400&style=flat-square
[latest-coverage]: https://coveralls.io/github/christhekeele/matcha?branch=latest
[latest-coverage-badge]: https://img.shields.io/coveralls/christhekeele/matcha/latest.svg?maxAge=86400&style=flat-square

<!-- Other -->

[elixir-version-requirements]: https://hexdocs.pm/elixir/Version.html#module-requirements
[changelog]: https://hexdocs.pm/matcha/changelog.html
[test-matrix]: https://github.com/christhekeele/matcha/actions/workflows/matrix.yml
[test-edge]: https://github.com/christhekeele/matcha/actions/workflows/edge.yml
[contributing]: https://hexdocs.pm/matcha/contributing.html
