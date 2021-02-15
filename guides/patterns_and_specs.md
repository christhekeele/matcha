Patterns and Specs
==================

Erlang matchspecs are a BEAM VM construct that can compile data-structure-matching procedures into something much more efficient[¹](#footnote-1) than a normal pattern-matching function.

This is possible because they only support a limited set of safe and optimized pattern-matching operations, as well as key kernel functions, much like guards.

They may support special 'virtual' function calls[²](#footnote-2) beyond guard-safe ones depending on context (ie `:table` or `:trace` usage). They can be validated at runtime, validated for special function utilization in specific contexts, and pre-compiled for performance optimization.

They are expressed in a tuple-and-atom-based DSL resembling an erlang AST, that allows injection of literals and bound variables. They can be difficult and intimidating to compose correctly in erlang, but even moreso in Elixir which does not align with the erlang syntax the DSL mimics.

Footnotes
---------

<span id="footnote-1">¹</span>

Per the [Erlang Matchspec Docs][erlang-matchspec-docs-efficiency]:

> The match specification in many ways works like a small function in Erlang, but is interpreted/compiled by the Erlang runtime system to something ***much more efficient*** than calling an Erlang function. 

[⏎](#content)

---

<span id="footnote-2">²</span>

Per the [Erlang Matchspec Docs][erlang-matchspec-docs-virtual], only match specifications for a `:trace` context use special 'virtual' function calls (`ActionCall`s).

The term 'virtual' is used here because none of these functions actually exist in erlang: unlike the rest of the matchspec-supported functions in the DSL, these calls have no concrete implementation that can be verified as correct by an erlang compiler.

`Matcha` works around this by defining no-op implementations of these functions in a dedicated `Matcha.Context.Trace` module, and referencing it during spec compilation.

[⏎](#content)

---


<!-- Links -->

[erlang-matchspec-docs-efficiency]: https://erlang.org/doc/apps/erts/match_spec.html#:~:text=works%20like%20a%20small%20function,something%20much%20more%20efficient

[erlang-matchspec-docs-virtual]: https://erlang.org/doc/apps/erts/match_spec.html#:~:text=ActionCall,silent