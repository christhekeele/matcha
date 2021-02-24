Patterns and Specs
==================

Overview
--------

One of the most optimized parts of the BEAM VM are its pattern-matching capabilities. These can filter and map in-memory data structures very efficiently, and are used to power conditional expressions and multi-head functions.

When performance is essential, Erlang gives us a way to compile our own data-structure filter-map procedures into that low-level VM form: match patterns and specifications. They are much more performant[¹](#footnote-1) than invoking the same procedure as a pattern-matching function, skipping a lot of VM internals and overhead.

This is possible because they only support a limited set of safe and optimized pattern-matching operations, as well as key kernel functions, much like guards. They are expressed in a tuple-and-atom-based DSL resembling an erlang AST, that allows injection of literals and bound variables.

What is a match pattern?
------------------------

A match pattern describes a data structure you can attempt to pattern-match against. You can think of it like one side of the input to the `Kernel.SpecialForms.=/2` match operator, or the head of a 1-arity function.

```ex
# match operator
iex> {x, y, x} = {1, 2, 1}
{1, 2, 1}
iex> {x, y, x} = {1, 2, 3}
** (MatchError) no match of right hand side value: {1, 2, 3}

# function
iex> fun = fn {x, y, x} -> {x, y, x} end
iex> fun.({1, 2, 1})
{1, 2, 1}
iex> fun.({1, 2, 3})
** (FunctionClauseError) no function clause matching...

# match patterns
iex> pattern = Matcha.pattern {x, y, x}
#Matcha.Pattern<{:"$1", :"$2", :"$1"}>
iex> Matcha.Pattern.match!(pattern, {1, 2, 1})
{1, 2, 1}
iex> Matcha.Pattern.match!(pattern, {1, 2, 3})
** (MatchError) no match of right hand side value: {1, 2, 3}
```

They have limited uses compared to match specifications, but certain `:ets` functions support them, so `Matcha` does as well.

What is a match spec?
---------------------

A match specification describes ways to transform a data structure if it matches certain criteria. You can think of it like the clauses of a `Kernel.SpecialForms.case/2` statement, or a 1-arity function.

```ex
# case statement
iex> case {3, 4} do
...>   {_x, 0} -> {:error, :division_by_zero}
...>   {x, y} -> {:ok, x / y}
...> end
{:ok, 0.75}
iex> case {3, 0} do
...>   {_x, 0} -> {:error, :division_by_zero}
...>   {x, y} -> {:ok, x / y}
...> end
{:error, :division_by_zero}
iex> case {3, 2, 1} do
...>   {_x, 0} -> {:error, :division_by_zero}
...>   {x, y} -> {:ok, x / y}
...> end
** (CaseClauseError) no case clause matching: {3, 2, 1}

# function
iex> fun = fn
  {_x, 0} -> {:error, :division_by_zero}
  {x, y} -> {:ok, x / y}
end
iex> fun.({3, 4})
{:ok, 0.75}
iex> fun.({3, 0})
{:error, :division_by_zero}
iex> fun.({3, 2, 1})
** (FunctionClauseError) no function clause matching...

# match specifications
iex> spec = Matcha.spec do
  {_x, 0} -> {:error, :division_by_zero}
  {x, y} -> {:ok, x / y}
end
#Matcha.Spec<[
  {{:"$1", 0}, [], [{{:error, :division_by_zero}}]},
  {{:"$1", :"$2"}, [], [{{:ok, {:/, :"$1", :"$2"}}}]}
]>
iex> Matcha.Spec.match!(spec, {1, 2, 1})
:ok
iex> Matcha.Spec.match!(spec, {1, 2, 3})
** (MatchError) no match of right hand side value: {1, 2, 3}

spec = Matcha.spec do; {_x, 0} -> {:error, :division_by_zero}; {x, y} -> {:ok, x / y}; end
```

They may support special 'virtual' function calls[²](#footnote-2) beyond guard-safe ones depending on context (ie `:table` or `:trace` usage). They can be validated at runtime, validated for special function utilization in specific contexts, and pre-compiled for performance optimization.



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