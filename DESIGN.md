# Design

This document describes the approach we take designing Matcha, the rationales behind it, and decisions that emerge from it.

## Goals

Matcha's first and only-est goal is to **make it easy to use match specs in Elixir**.

Every design decision is informed by this goal; if a feature is in tension with ease-of-use, it gets axed.

It is certain that Matcha's design limits what is possible, compared to hand-written match specs.
It is possible that new and powerful Elixir tooling around match specs cannot be built on top of Matcha.
However, this is all moot if _nobody is using match specs in Elixir_.
If Matcha is eventually discarded because the Elixir community is clamouring for a match spec tool that does more,
then it has succeeded.

## Decisions

### Documentation

- **_Documentation is the most important feature of Matcha._**

  The most powerful tools and simplest APIs are useless if not accessible.
  Indeed, as of writing this is one of the major obstacles to Elixir match spec and tracing usage today.

  One could even argue that most of the `Matcha` codebase is an excuse to describe how to use match specs,
  with its modules just being a place to introduce related concepts,
  and its functions a place to document various features.
  Any actual functionality is incidental and just an attempt to hide complexity where possible,
  to provide simpler documentation.

  Corrections to and improvements on documentation should be prioritized as their own patch release,
  to deliver this ease-of-use to library users as soon as possible, rather than waiting for code to ship with it.

- **_Error messages are our most important documentation._**

  Even with great tooling, match specs and tracing are not the easiest to get correct.

  Error messages are the best opportunity we have to steer people right, and are effectively just-in-time documentation.

### Compiler

- **_Matcha compiles Elixir into match specs._**

  After all, the easiest way for an Elixir developer to write a match spec is to write Elixir code instead.

- **_Matcha fully expands all code through the Elixir compiler first._**

  This ensures that the code a user writes is valid Elixir, and can be,
  say, cut out of a match spec and put into an anonymous function instead; or vice-versa.

  It also ensures that invalid code is presented via the same familiar errors, warnings,
  and line numbers as the user's installed Elixir sees them.

  It also provides the best possible macro support within match specs possible.

- **_Matcha immediately validates the match specs it compiles Elixir code into._**

  This makes it a compile-time error not just to provide invalid Elixir code, but to craft an invalid match spec.

- **_Matcha provides concrete implementations of 'virtual' match spec functions._**

  Specifically, all of the 'instructions' used to drive the tracing engine.
  These have no real-world representation in the BEAM VM.

  Giving them a concrete implementation has numerous benefits:

  - It provides a place to anchor first-class documentation about them
  - It allows dialyzer to type-check their inputs
  - When defined just in a particular context, it allows "calls" to them in the wrong context to raise an intuitive undefined function error, same as any other unavailable function.

### Contexts

- **_Contexts are extensible._**

  The ultimate surface area of functions that accept match specs are closely coupled to
  the two erlang contexts — `:table` and `:trace` — and the functions it offers to invoke them in those contexts.

  Rather than hardcoding knowledge about how any given spec should behave in one of these two contexts,
  we defer to an abstract behaviour.

  While we can't offer more _functionality_ around match specs than what erlang provides,
  this does allow us to build new **_use-cases_** on top of them,
  with custom validation, errors/warnings, and behaviour when invoked.

- **_Functions allowed in contexts are derived_** to the extent possible.

  Delegating the work of determining which base function calls are allowed to `:erl_internal`
  lets Matcha work without change if, say, a new guard BIF is introduced to the language.

  This isn't fully possible today since we have to handle `tuple_size` and `is_record` as special cases,
  but nothing else in the Common context is hard-coded.
