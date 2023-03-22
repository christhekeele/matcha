# 🍵 Matcha

<!-- MODULEDOC BLURB -->

> **_First-class match specifications for Elixir._**

<!-- MODULEDOC BLURB -->

[![Version][hex-pm-version-badge]][hex-pm-versions]
[![Documentation][docs-badge]][docs]
[![Dependencies][deps-badge]][deps]
[![License][hex-pm-license-badge]][hex-pm-package]
[![Benchmarks][benchmarks-badge]][benchmarks]

|         👍         |                  [Test Suite][suite]                  |                   [Test Coverage][coverage]                    |
| :----------------: | :---------------------------------------------------: | :------------------------------------------------------------: |
| [Release][release] | [![Build Status][release-suite-badge]][release-suite] | [![Coverage Status][release-coverage-badge]][release-coverage] |
|  [Latest][latest]  |  [![Build Status][latest-suite-badge]][latest-suite]  |  [![Coverage Status][latest-coverage-badge]][latest-coverage]  |

## Usage

### Installation

`Matcha` is distributed via [hex.pm][hex-pm], you can install it with your dependency manager of choice using the config provided on its [hex.pm package][hex-pm-package] listing.

<!-- MODULEDOC SNIPPET -->
<!--
  all hyperlinks in this snippet must be inline,
  rather than using markdown link references
-->

### Synopsis

`Matcha` offers tight integration with Elixir and match specifications.

Match specifications are a BEAM VM feature that can execute de-structuring, pattern matching, and re-structring operations very close-to-the-metal. They can be used to efficiently:

- [filter/map in-memory data](https://www.erlang.org/doc/man/ets.html#match_spec_run-2)
- [find ETS objects](https://erlang.org/doc/man/ets.html#select-2)
- [trace specific function calls](https://erlang.org/doc/man/dbg.html#tp-2)

However, they are notoriously difficult to compose and use. Matcha makes this intuitive with ergonomic macros to compose them, and a high-level API with which to use them.

### Examples

```elixir
# Turn Elixir code into a match specification,
#  then use it to filter/map some data
iex> require Matcha
...> Matcha.spec do
...>   {x, y, z} -> x + y + z
...> end
...> |> Matcha.Spec.run!([
...>   {1, 2, 3},
...>   {1, 2},
...>   {1, 2, 3, 4},
...>   {4, 5, 6}
...> ])
[6, 15]
```

This is one way to run test and develop match specifications, but they truly shine in table and tracing applications!

### Guides

Check out [the interactive usage guides](https://hexdocs.pm/matcha/guide-usage.html#content), including using Matcha for:

- [filtering & mapping data](https://hexdocs.pm/matcha/guide-filtering-and-mapping.html#content)
- [selecting objects from tables](https://hexdocs.pm/matcha/guide-tables.html#content)
- [tracing function calls](https://hexdocs.pm/matcha/guide-tracing.html#content)

<!-- MODULEDOC SNIPPET -->

### Documentation

Complete documentation, including guides, are hosted online on [hexdocs.pm][docs].

## Contributing

Contributions are welcome! Check out the [contributing guide][contributing] for more information, and suggestions on where to start.

## Supported Versions

Matcha strives to support the most recent three versions of Elixir and the erlang/OTPs they support. The canonical list of supported combinations is available by checking the latest successful [test matrix run][test-matrix], but boils down to:

- Elixir 1.12.x
  - OTP 22.x
  - OTP 23.x
  - OTP 24.x
- Elixir 1.13.x
  - OTP 22.x
  - OTP 23.x
  - OTP 24.x
  - OTP 25.x
- Elixir 1.14.x
  - OTP 23.x
  - OTP 24.x
  - OTP 25.x

Earlier versions of Elixir tend to work well, back to Elixir 1.10, but the test suite often uses newer syntax that is complicated to circumvent when testing on older versions (ex. range step literals), so we don't officially commit to being compatible with them since they are not a part of the suite. Versions that may work include:

- Elixir 1.10.x
  - OTP 21.x
  - OTP 22.x
  - OTP 23.x
- Elixir 1.11.x
  - OTP 21.x
  - OTP 22.x
  - OTP 23.x
  - OTP 24.x

Since `Matcha` pokes around in compiler internals, it is important to get ahead of upcoming changes to the language.
This is accomplished with [nightly builds][test-edge] against the latest versions of Elixir, erlang/OTP, and dependencies;
which catches issues like [internal compiler function signature changes](https://github.com/christhekeele/matcha/commit/27f3f34284349d807fcd2817a04cb4628498a7eb#diff-daf93cf4dc6034e9862d0d844c783586210ea822ae6ded51d925b0ac9e09766bR31-R43)
well in advance of release.

<!-- LINKS & IMAGES -->

<!-- Hex -->

[hex-pm]: https://hex.pm
[hex-pm-package]: https://hex.pm/packages/matcha
[hex-pm-versions]: https://hex.pm/packages/matcha/versions
[hex-pm-version-badge]: https://img.shields.io/hexpm/v/matcha.svg?cacheSeconds=86400&style=flat-square
[hex-pm-downloads-badge]: https://img.shields.io/hexpm/dt/matcha.svg?cacheSeconds=86400&style=flat-square
[hex-pm-license-badge]: https://img.shields.io/badge/license-MIT-7D26CD.svg?cacheSeconds=86400&style=flat-square

<!-- Docs -->

[docs]: https://hexdocs.pm/matcha/index.html
[docs-guides]: https://hexdocs.pm/matcha/usage.html#content
[docs-badge]: https://img.shields.io/badge/documentation-online-purple?cacheSeconds=86400&style=flat-square

<!-- Deps -->

[deps]: https://hex.pm/packages/matcha
[deps-badge]: https://img.shields.io/badge/dependencies-1-blue?cacheSeconds=86400&style=flat-square

<!-- Benchmarks -->

[benchmarks]: https://christhekeele.github.io/matcha/bench
[benchmarks-badge]: https://img.shields.io/badge/benchmarks-online-2ab8b5?cacheSeconds=86400&style=flat-square

<!-- Status -->

[suite]: https://github.com/christhekeele/matcha/actions?query=workflow%3A%22Test+Suite%22
[coverage]: https://coveralls.io/github/christhekeele/matcha

<!-- Release Status -->

[release]: https://github.com/christhekeele/matcha/tree/release
[release-suite]: https://github.com/christhekeele/matcha/actions?query=workflow%3A%22Test+Suites%22+branch%3Arelease
[release-suite-badge]: https://img.shields.io/github/actions/workflow/status/christhekeele/matcha/test-suite.yml?branch=release&cacheSeconds=86400&style=flat-square
[release-coverage]: https://coveralls.io/github/christhekeele/matcha?branch=release
[release-coverage-badge]: https://img.shields.io/coveralls/christhekeele/matcha/release.svg?cacheSeconds=86400&style=flat-square

<!-- Latest Status -->

[latest]: https://github.com/christhekeele/matcha/tree/latest
[latest-suite]: https://github.com/christhekeele/matcha/actions?query=workflow%3A%22Test+Suites%22+branch%3Alatest
[latest-suite-badge]: https://img.shields.io/github/actions/workflow/status/christhekeele/matcha/test-suite.yml?branch=latest&cacheSeconds=86400&style=flat-square
[latest-coverage]: https://coveralls.io/github/christhekeele/matcha?branch=latest
[latest-coverage-badge]: https://img.shields.io/coveralls/christhekeele/matcha/latest.svg?cacheSeconds=86400&style=flat-square

<!-- Other -->

[elixir-version-requirements]: https://hexdocs.pm/elixir/Version.html#module-requirements
[changelog]: https://hexdocs.pm/matcha/changelog.html
[test-matrix]: https://github.com/christhekeele/matcha/actions/workflows/test-matrix.yml
[test-edge]: https://github.com/christhekeele/matcha/actions/workflows/test-edge.yml
[contributing]: https://hexdocs.pm/matcha/contributing.html
