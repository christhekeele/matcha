defmodule Matcha do
  @moduledoc """
  First-class match specification and match patterns for Elixir.

  The BEAM VM Match patterns and specs
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

  For more information on match patterns, consult the `Matcha.Pattern` moduledocs.

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
  For more information on match contexts, consult the `Matcha.Context` moduledocs.

  For more information on match specs, consult the `Matcha.Spec` moduledocs.

  ## Examples

      iex> require Matcha
      ...> Matcha.spec do
      ...>   {x, y, x} -> {y, x}
      ...> end
      #Matcha.Spec<[{{:"$1", :"$2", :"$1"}, [], [{{:"$2", :"$1"}}]}], context: :filter_map>

  """
  defmacro spec(context \\ @default_context_type, _spec = [do: clauses]) do
    context = Rewrite.resolve_context(context)

    source =
      %Rewrite{env: __CALLER__, context: context, source: clauses}
      |> Rewrite.ast_to_spec_source(clauses)

    quote location: :keep do
      %Spec{source: unquote(source), context: unquote(context)}
      |> Spec.validate!()
    end
  end
end
