Matcha
======

> ***First-class match specification and match patterns for Elixir***

Motivation
----------

### The Erlang

Erlang matchspecs are a BeamVM construct that can compile data-structure-matching procedures into something much more efficient[^more-efficient] than a normal pattern-matching function.

This is possible because they only support a limited set of safe and optimized pattern-matching operations, as well as key kernel functions, much like guards.

They may support special 'virtual' function calls[^virtual-context-function-calls] beyond guard-safe ones depending on context (ie `ets` or `trace` usage). They can be validated at runtime, validated for special function utilization in specific contexts, and pre-compiled for performance optimization.

They are expressed in a tuple-and-atom-based DSL resembling an erlang AST, that allows injection of literals and bound variables. They can be difficult and intimidating to compose correctly in erlang, but even moreso in Elixir which does not align with the erlang syntax the DSL mimics.

### The DSL

Sadly, the documentation of this erlang-esque tuple-and-atom DSL is very informally specified. [^informally-specified]. A match specification 
### The Elixir

This library seeks to explore:

- macros that can convert valid Elixir into matchspec DSL
- helpful warnings and errors when compiling them
- additions to the standard library to work with them
- modifications to the standard library to consume them

Goals
-----

- Support both tracing and table matching
- Support both match patterns and match specs
- Emit compile-time errors and warnings
- Use the elixir compiler as the single source of truth for expansion
- Use erlang as the single source of truth for contextual validity





[^more-efficient]: [Erlang MatchSpec Docs](https://erlang.org/doc/apps/erts/match_spec.html#:~:text=works%20like%20a%20small%20function,something%20much%20more%20efficient): The match specification in many ways works like a small function in Erlang, but is interpreted/compiled by the Erlang runtime system to something much more efficient than calling an Erlang function. 

[^virtual-context-function-calls]: In the author's experience, and after consulting documentation, only match specifications for a `tracing` context [support 'special virtual' function calls](https://erlang.org/doc/apps/erts/match_spec.html#:~:text=ActionCall,silent). The term 'virtual' is used here because none of these function calls actually exist in erlang: unlike the rest of the matchspec-supported functions in the DSL, these calls have no concrete implementation that can be verified as correct by an erlang compiler. Working around this contextual compiler-unverifiable virtual function support is one of the goals of the project.

[^informally-specified]: [Erlang MatchSpec Docs](https://erlang.org/doc/apps/erts/match_spec.html#:~:text=A%20match%20specification%20used%20in%20tracing,the%20following%20informal%20grammar): A match specification used in *tracing*|*ets* can be described in the following ***informal*** grammar...

Text<span id="a1">[¹](#1)</span>

<span id="1">¹</span> Footnote.[⏎](#a1)<br>