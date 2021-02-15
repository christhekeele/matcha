Matcha
======

> ***First-class match specification and match patterns for Elixir.***

[![Version][hex-version-badge]][hex]
[![Downloads][hex-downloads-badge]][hex]
[![Documentation][docs-badge]][docs]
[![Dependencies][deps-badge]][deps]
[![License][hex-license-badge]][hex]

|     :thumbsup:     |                  [Test Suite][suite]                   |         [Test Coverage][coverage]          |
|:------------------:|:------------------------------------------------------:|:------------------------------------------:|
| [Release][release] |  [![Build Status][release-suite-badge]][release-suite] | ![Coverage Status][release-coverage-badge] |
|  [Latest][latest]  |   [![Build Status][latest-suite-badge]][latest-suite]  | ![Coverage Status][latest-coverage-badge]  |

Synopsis
--------

Matcha offers tight integration with Elixir and match patterns/specifications.

### Features

- Supports compiling Elixir code into match patterns/specs, similar to [`ex2ms`](#ex2ms)
- Represents patterns/specs as structs, allowing for protocol support
- Offers higher-level APIs for validation and utilization of patterns/specs
- Supports table, tracing, and custom spec contexts in both compiler and APIs

For more information about the BEAM VM's match patterns and specifications in general, consult [this guide][docs-patterns-and-specs].

### Motivation

Erlang's match pattern and spec *capabilities* are pretty powerful. However, the syntax for ***composing*** them is an unintuitive DSL that loosely mirrors a non-existent erlang AST, and built-in ***support*** for using them is limited to a few functions.

#### Composition

The tuple-and-atom spec DSL is very informally specified[¹](#footnote-1) and hard to debug. It can be frustrating for erlang programmers to write, and is often even harder for Elixir developers who can be disconnected from the erlang-oriented syntax.

There is a parse transform for turning erlang functions into matchspecs, but that is not readily accessible from the Elixir ecosystem. The `Ex2ms` library offers similar functionality for Elixir, but has [certain limitations](#ex2ms) of its own.

This sort of compile-time transformation is exactly what Elixir's macro system was built to do well, and `Matcha` offers powerful macros for composing match patterns and specs.

#### Support

The erlang standard library only offers a few functions scattered across several modules for working with the spec DSL.

I'd love to enable more ways to tap into this cool feature, so `Matcha` offers a more user-friendly API for working with match patterns and specs in different contexts.

Installation
------------

- Add `matcha` to your Mix project's dependencies specification, ie:

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

Usage
-----

For in-depth usage instructions, refer to [the online documentation][docs].


Alternatives
------------

### Ex2ms

[`Ex2ms`](https://github.com/ericmj/ex2ms) is a great project, and served as the seed for this one! `Matcha` extends it to include match patterns as well as specs, wraps them in structs, and offers a library API for validating and working with them.

Additionally, there are a few limitations in the `Ex2ms` matchspec compiler that this project seeks to overcome:

- `Matcha` invokes the internal Elixir compiler `:elixir_expand.expand/2`, which lets it play a little better with other macros and simplifies the expansion pass.
- `Matcha` also invokes the internal erlang compiler `:erl_internal` functions to be a little more future-proof and less hard-coded about what's allowed in specs.
- `Matcha` introduces the concept of functional contexts to support tracing matchspecs, which support non-existent "virtual functions" just for tracing purposes.

Footnotes
---------

<span id="footnote-1">¹</span>

Per the [Erlang Matchspec Docs][erlang-matchspec-docs-informal]:

> A match specification used in *tracing*/*ets* can be described in the following ***informal*** grammar...

[⏎](#composition)

---

<!-- Links -->

[hex]: https://hex.pm/packages/matcha
[hex-version-badge]:   https://img.shields.io/hexpm/v/matcha.svg?maxAge=86400&style=flat-square
[hex-downloads-badge]: https://img.shields.io/hexpm/dt/matcha.svg?maxAge=86400&style=flat-square
[hex-license-badge]:   https://img.shields.io/badge/license-MIT-7D26CD.svg?maxAge=86400&style=flat-square

[docs]: https://hexdocs.pm/matcha/index.html
<!-- [docs-badge]: https://inch-ci.org/github/christhekeele/matcha.svg?branch=release&style=flat-square -->
[docs-badge]: https://img.shields.io/badge/documentation-online-purple?maxAge=86400&style=flat-square
[docs-patterns-and-specs]: https://hexdocs.pm/matcha/patterns-and-specs.html#content

[deps]: https://hex.pm/packages/matcha
[deps-badge]: https://img.shields.io/badge/dependencies-none-blue?maxAge=86400&style=flat-square

[suite]: https://github.com/christhekeele/matcha/actions?query=workflow%3A%22Test+Suite%22
[coverage]: https://coveralls.io/github/christhekeele/matcha

[release]: https://github.com/christhekeele/matcha/tree/release
[release-suite]: https://github.com/christhekeele/matcha/actions?query=workflow%3A%22Test+Suite%22+branch%3Arelease
[release-suite-badge]: https://img.shields.io/github/checks-status/christhekeele/matcha/release.svg?maxAge=86400&style=flat-square
[release-coverage-badge]: https://img.shields.io/coveralls/christhekeele/matcha/release.svg?maxAge=86400&style=flat-square

[latest]: https://github.com/christhekeele/matcha/tree/latest
[latest-suite]: https://github.com/christhekeele/matcha/actions?query=workflow%3A%22Test+Suite%22+branch%3Alatest
[latest-suite-badge]: https://img.shields.io/github/checks-status/christhekeele/matcha/latest.svg?maxAge=86400&style=flat-square
[latest-coverage-badge]: https://img.shields.io/coveralls/christhekeele/matcha/latest.svg?maxAge=86400&style=flat-square

[erlang-matchspec-docs-informal]: https://erlang.org/doc/apps/erts/match_spec.html#:~:text=A%20match%20specification%20used%20in%20tracing,the%20following%20informal%20grammar