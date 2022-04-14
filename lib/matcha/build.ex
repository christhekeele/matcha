defmodule Matcha.Build do
  alias Matcha.Context
  alias Matcha.Rewrite

  alias Matcha.Pattern
  alias Matcha.Spec
  alias Matcha.Trace

  @default_context_module Context.Match
  # @default_context_type @default_context_module.__context_name__()
  @default_context_type :match

  @spec pattern(Macro.t()) :: Macro.t()
  @doc """
  Builds a `Matcha.Pattern` that represents a "filter" operation on a given input.

  Match patterns represent a "filter" operation on a given input,
  ignoring anything that does not fit the match "shape" specified.

  For more information on match patterns, consult the `Matcha.Pattern` docs.

  ## Examples

      iex> require Matcha
      ...> pattern = Matcha.pattern({x, y, x})
      #Matcha.Pattern<{:"$1", :"$2", :"$1"}>
      iex> Matcha.Pattern.match?(pattern, {1, 2, 3})
      false
      iex> Matcha.Pattern.match?(pattern, {1, 2, 1})
      true

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
  Builds a `Matcha.Spec` that represents a "filter+map" operation on a given input.

  The `context` may be `:match`, `:table`, `:trace`, or a `Matcha.Context` module.
  This is detailed in the `Matcha.Context` docs.

  For more information on match specs, consult the `Matcha.Spec` docs.

  ## Examples

      iex> require Matcha
      ...> Matcha.spec do
      ...>   {x, y, x}
      ...>     when x > y and y > 0
      ...>       -> x
      ...>   {x, y, y}
      ...>     when x < y and y < 0
      ...>       -> y
      ...> end
      #Matcha.Spec<[{{:"$1", :"$2", :"$1"}, [{:andalso, {:>, :"$1", :"$2"}, {:>, :"$2", 0}}], [:"$1"]}, {{:"$1", :"$2", :"$2"}, [{:andalso, {:<, :"$1", :"$2"}, {:<, :"$2", 0}}], [:"$2"]}], context: :match>

  """
  defmacro spec(context \\ @default_context_type, spec)

  defmacro spec(context, _spec = [do: clauses]) when is_list(clauses) do
    Enum.each(clauses, fn
      {:->, _, _} ->
        :ok

      other ->
        raise ArgumentError,
          message:
            "#{__MODULE__}.spec/2 must be provided with `->` clauses," <>
              " got: `#{Macro.to_string(other)}`"
    end)

    context =
      context
      |> Rewrite.perform_expansion(__CALLER__)
      |> Rewrite.resolve_context()

    source =
      %Rewrite{env: __CALLER__, context: context, source: clauses}
      |> Rewrite.ast_to_spec_source(clauses)

    quote location: :keep do
      %Spec{source: unquote(source), context: unquote(context)}
      |> Spec.validate!()
    end
  end

  defmacro spec(_context, _spec = [do: not_a_list]) when not is_list(not_a_list) do
    raise ArgumentError,
      message:
        "#{__MODULE__}.spec/2 must be provided with `->` clauses," <>
          " got: `#{Macro.to_string(not_a_list)}`"
  end

  defmacro spec(_context, not_a_block) do
    raise ArgumentError,
      message:
        "#{__MODULE__}.spec/2 requires a block argument," <>
          " got: `#{Macro.to_string(not_a_block)}`"
  end
end
