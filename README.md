Matcha
======

> ***Exploratory Matchspec Macros for Elixir***

Motivation
----------

Matchspecs are an `erlang` construct that can compile data-structure-matching procedures into something more efficient than a normal function.

They only support a limited set of pattern-matching operations and kernel functions, much like guards, and are useful for making performant `ets` and `trace` selections.

They are expressed in a tuple-and-atom based DSL not dissimilar to an erlang AST, and can be difficult and intimidating to compose correctly.

This library seeks to provide macros that can convert valid Elixir into matchspec tuples at compile time.

Goals
-----

- Support both tracing and tables
- Support both match patterns and match specs
- Emit compile-time errors and warnings
- Use the elixir compiler as the single source of truth for expansion
