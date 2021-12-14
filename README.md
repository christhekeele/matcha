# ☕️ Matcha

> **_First-class match specification tooling for Elixir._**

[![Version][hex-version-badge]][hex]
[![Downloads][hex-downloads-badge]][hex]
[![Documentation][docs-badge]][docs]
[![Dependencies][deps-badge]][deps]
[![License][hex-license-badge]][hex]

|         👍         |                  [Test Suite][suite]                  |         [Test Coverage][coverage]          |
| :----------------: | :---------------------------------------------------: | :----------------------------------------: |
| [Release][release] | [![Build Status][release-suite-badge]][release-suite] | ![Coverage Status][release-coverage-badge] |
|  [Latest][latest]  |  [![Build Status][latest-suite-badge]][latest-suite]  | ![Coverage Status][latest-coverage-badge]  |

## Synopsis

Matcha offers tight integration with Elixir and match specifications.

Match specifications are a BEAM VM tool for running **simple** filter/map operations very close-to-the-metal, _often several thousand times more performant than a comparable `Enum` operation_. They can be used to efficiently [find ETS objects][ets-select] and [trace specific function calls][dbg-tp].

However, they are notoriously difficult to compose and use. Matcha makes this intuitive with powerful macros and a fluent API with which to manipulate them.

Check out [the guides][guides-overview] for an overview of these features and how to use them!

## Installation

- Add `:matcha` to your Mix project's dependencies specification, ie:

  ```ex
  # mix.exs
  def deps do
    [
        #...
        {:matcha, "~> 0.1"},
        #...
    ]
  end
  ```

- Install your updated dependencies, ie:

  ```sh
  $ mix deps.get
  ```

## Usage

See [the guides][guides-overview] for general information, or dive right into the [module documentation online][docs].

## Goals

Matcha aims to make it **_easy to use_** match specs in Elixir. This includes:

- Passing through the Elixir compiler to get familiar errors and warnings.
- Raising with informative error messages where we can, and friendlier ones when surfacing erlang errors.
- Providing high-quality documentation on not just Matcha usage, but match specs and their use-cases in general.
- Offering high-level APIs around match spec usage so it is trivial to leverage their power.
- Defining concrete implementations of the 'virtual' function calls for better documentation, compile-time check, and typechecking integration.

<!-- Links -->

[hex]: https://hex.pm/packages/matcha
[hex-version-badge]: https://img.shields.io/hexpm/v/matcha.svg?maxAge=86400&style=flat-square
[hex-downloads-badge]: https://img.shields.io/hexpm/dt/matcha.svg?maxAge=86400&style=flat-square
[hex-license-badge]: https://img.shields.io/badge/license-MIT-7D26CD.svg?maxAge=86400&style=flat-square

<!-- [docs-badge]: https://inch-ci.org/github/christhekeele/matcha.svg?branch=release&style=flat-square -->

[docs]: https://hexdocs.pm/matcha/index.html
[docs-badge]: https://img.shields.io/badge/documentation-online-purple?maxAge=86400&style=flat-square
[deps]: https://hex.pm/packages/matcha
[deps-badge]: https://img.shields.io/badge/dependencies-1_(optional)-blue?maxAge=86400&style=flat-square
[suite]: https://github.com/christhekeele/matcha/actions?query=workflow%3A%22Test+Suite%22
[coverage]: https://coveralls.io/github/christhekeele/matcha
[release]: https://github.com/christhekeele/matcha/tree/release
[release-suite]: https://github.com/christhekeele/matcha/actions?query=workflow%3A%22Test+Suite%22+branch%3Arelease
[release-suite-badge]: https://img.shields.io/github/checks-status/christhekeele/matcha/release.svg?maxAge=86400&style=flat-square

<!-- [release-coverage-badge]: https://img.shields.io/coveralls/christhekeele/matcha/release.svg?maxAge=86400&style=flat-square -->

[release-coverage-badge]: https://coveralls.io/repos/github/christhekeele/matcha/badge.svg?branch=release
[latest]: https://github.com/christhekeele/matcha/tree/latest
[latest-suite]: https://github.com/christhekeele/matcha/actions?query=workflow%3A%22Test+Suite%22+branch%3Alatest
[latest-suite-badge]: https://img.shields.io/github/checks-status/christhekeele/matcha/latest.svg?maxAge=86400&style=flat-square

<!-- [latest-coverage-badge]: https://img.shields.io/coveralls/christhekeele/matcha/latest.svg?maxAge=86400&style=flat-square -->

[latest-coverage-badge]: https://coveralls.io/repos/github/christhekeele/matcha/badge.svg?branch=latest
[guides-overview]: overview.html#content
[ets-select]: https://erlang.org/doc/man/ets.html#select-2
[dbg-tp]: https://erlang.org/doc/man/dbg.html#tp-2
