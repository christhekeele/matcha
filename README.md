# ☕️ Matcha

<!-- MODULEDOC BLURB !-->

> **_First-class match specification tooling for Elixir._**

<!-- MODULEDOC BLURB !-->

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

<!-- MODULEDOC SNIPPET !-->

`Matcha` offers tight integration with Elixir and match specifications.

Match specifications are a BEAM VM tool for running **simple** pattern matching operations very close-to-the-metal, _often several thousand times more performant than a comparable `Enum` operation_. They can be used to efficiently:

- [filter/map in-memory data](https://www.erlang.org/doc/man/ets.html#match_spec_run-2)
- [find ETS objects](https://erlang.org/doc/man/ets.html#select-2)
- [trace specific function calls](https://erlang.org/doc/man/dbg.html#tp-2)

However, they are notoriously difficult to compose and use. Matcha makes this intuitive with ergonomic macros and a fluent API with which to manipulate them.

## Usage

```elixir
require Matcha

iex> spec =
...> Matcha.spec do
...>     {x, y, z} -> {x, y, z}
...>   end
#Matcha.Spec<[{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}], context: :filter_map>
```

For more information, check out [the interactive usage guides](https://hexdocs.pm/matcha/usage.html#content), including using Matcha for:

- [filtering & mapping data](https://hexdocs.pm/matcha/usage/filtering-and-mapping.html#content)
- [selecting records from tables](https://hexdocs.pm/matcha/usage/tables.html#content)
- [tracing function calls](https://hexdocs.pm/matcha/usage/tracing.html#content)

<!-- MODULEDOC SNIPPET !-->

## Goals

Matcha aims to make it **_easy to use_** match specs in Elixir. This includes:

- Passing through the Elixir compiler to get familiar errors and warnings.
- Raising with informative error messages where we can, and friendlier ones when surfacing erlang errors.
- Providing high-quality documentation on not just Matcha usage, but match specs and their use-cases in general.
- Offering high-level APIs around match spec usage so it is trivial to leverage their power.
- Defining concrete implementations of the 'virtual' function calls for better documentation, compile-time check, and typechecking integration.

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

  Matcha is not yet fully stable (at version `1.0.0`)!
  To help get it there, consider trying the cutting edge version in your project,
  to see how it behaves or to report issues, via:

  ```ex
  # mix.exs
  def deps do
    [
        #...
        {:matcha, github: "christhekeele/matcha", branch: "latest"}},
        #...
    ]
  end
  ```

- Install your updated dependencies, ie:

  ```sh
  $ mix deps.get
  ```

## Further Reading

See [the guides][docs-guides] for general information, or dive right into the [module documentation online][docs]!

<!-- LINKS & IMAGES-->

<!-- Package -->

[hex]: https://hex.pm/packages/matcha
[hex-version-badge]: https://img.shields.io/hexpm/v/matcha.svg?maxAge=86400&style=flat-square
[hex-downloads-badge]: https://img.shields.io/hexpm/dt/matcha.svg?maxAge=86400&style=flat-square
[hex-license-badge]: https://img.shields.io/badge/license-MIT-7D26CD.svg?maxAge=86400&style=flat-square

<!-- Docs -->

[docs]: https://hexdocs.pm/matcha/index.html
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
[release-coverage-badge]: https://img.shields.io/coveralls/christhekeele/matcha/release.svg?maxAge=86400&style=flat-square

<!-- Latest Status -->

[latest]: https://github.com/christhekeele/matcha/tree/latest
[latest-suite]: https://github.com/christhekeele/matcha/actions?query=workflow%3A%22Test+Suite%22+branch%3Alatest
[latest-suite-badge]: https://img.shields.io/github/checks-status/christhekeele/matcha/latest.svg?maxAge=86400&style=flat-square
[latest-coverage-badge]: https://img.shields.io/coveralls/christhekeele/matcha/latest.svg?maxAge=86400&style=flat-square
