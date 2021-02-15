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

The tuple-and-atom spec DSL is very informally specified<span id="footnote-ref-1">[¹](#footnote-1)</span> and hard to debug. It can be frustrating for erlang programmers to write, and is often even harder for Elixir developers who can be disconnected from the erlang-oriented syntax.

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

[`Ex2ms`](https://github.com/ericmj/ex2ms) is a great project, and served as the seed for this one! `Matcha` extends it by match patterns as well as specs, wrapping them in structs, and offering an extensive API for validating and working with them.

Furthermore, the `Ex2ms` matchspec compiler has a few limitations that this project seeks to overcome:

- It doesn't tap into Elixir compiler internals, so can't quite translate as many Elixir code constructs. `Matcha` invokes `:elixir_expand.expand/2` to cover a little more ground.
- It doesn't tap into erlang compiler internals, so must hard-code what functions are allowed in spec bodies. `Matcha` defers to `:erl_internal` to be a little more future-proof.
- It doesn't support compiling specs for tracing contexts. Tracing is very fertile unexplored ground in the Elixir ecosystem, so `Matcha` introduces the concept of different contexts to support investigation in this domain.

Footnotes
---------

---

<span id="footnote-1">¹</span> per the [Erlang Matchspec Docs][erlang-matchspec-grammar-docs]:

> A match specification used in *tracing*/*ets* can be described in the following ***informal*** grammar...

[⏎](#footnote-ref-1)

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

[erlang-matchspec-grammar-docs]: https://erlang.org/doc/apps/erts/match_spec.html#:~:text=A%20match%20specification%20used%20in%20tracing,the%20following%20informal%20grammar