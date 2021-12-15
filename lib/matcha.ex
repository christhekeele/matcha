defmodule Matcha do
  @moduledoc """
  First-class match specification and match patterns for Elixir.

  ### Known Limitations

  Currently, it is not possible to:

  - Use the `Kernel.in/2`  macro in guards. *(see: [open issue](https://github.com/christhekeele/matcha/issues/2))*
  - Use the `Kernel.tuple_size/1` or `:erlang.tuple_size/1` guards. *(see: [documentation](https://hexdocs.pm/matcha/Matcha.Context.Common.html#module-limitations))*
    - This is a fundamental limitation of match specs.
  - Use any `is_record` guards (neither Elixir's implementation because of the  `Kernel.tuple_size/1` limitation above, nor erlang's implementation for other reasons). *(see: [documentation](https://hexdocs.pm/matcha/Matcha.Context.Common.html#module-limitations))*
  - Both destructure values from a data structure into bindings, and assign the datastructure to a variable, except at the top-level of a clause.
    - This is how match specs work by design; though there may be a work-around using `:erlang.map_get/2` for maps, but at this time introducing an inconsistency doesn't seem worth it.
  """

  alias Matcha.Context
  alias Matcha.Rewrite

  alias Matcha.Pattern
  alias Matcha.Spec

  @default_context_module Context.FilterMap
  @default_context_type @default_context_module.__context_name__()

  @spec pattern(Macro.t()) :: Macro.t()
  @doc """
  Macro for building a `Matcha.Pattern`.

  For more information on match patterns, consult the `Matcha.Pattern` docs.

  ## Examples

      iex> require Matcha
      ...> Matcha.pattern({x, y})
      #Matcha.Pattern<{:"$1", :"$2"}>

  """
  defmacro pattern(pattern) do
    source =
      %Rewrite{env: __CALLER__, source: pattern}
      |> Rewrite.ast_to_pattern_source(pattern)

    quote location: :keep do
      %Pattern{source: unquote(source)}
      |> Pattern.validate!()
    end
  end

  @spec spec(Context.t(), Macro.t()) :: Macro.t()
  @doc """
  Macro for building a `Matcha.Spec`.

  The `context` may be `:filter_map`, `:table`, `:trace`, or a `Matcha.Context` module.
  For more information on match contexts, consult the `Matcha.Context` docs.

  For more information on match specs, consult the `Matcha.Spec` docs.

  ## Examples

      iex> require Matcha
      ...> Matcha.spec do
      ...>   {x, y, x} -> {y, x}
      ...> end
      #Matcha.Spec<[{{:"$1", :"$2", :"$1"}, [], [{{:"$2", :"$1"}}]}], context: :filter_map>

  """
  defmacro spec(context \\ @default_context_type, spec)

  defmacro spec(context, _spec = [do: clauses]) do
    {expanded_context, _env} = :elixir_expand.expand(context, __CALLER__)
    context = Rewrite.resolve_context(expanded_context)

    source =
      %Rewrite{env: __CALLER__, context: context, source: clauses}
      |> Rewrite.ast_to_spec_source(clauses)

    quote location: :keep do
      %Spec{source: unquote(source), context: unquote(context)}
      |> Spec.validate!()
    end
  end

  defmacro spec(_context, not_a_block) do
    raise ArgumentError,
      message:
        "#{__MODULE__}.spec/2 requires a block argument," <>
          " got: `#{Macro.to_string(not_a_block)}`"
  end
end
