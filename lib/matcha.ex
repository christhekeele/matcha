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
  @default_context_type @default_context_module.__name__()

  # TODO
  # defmacro sigil_m, do: :noop
  # defmacro sigil_M, do: :noop

  @spec resolve_context(module() | Context.t()) :: Context.t()
  defp resolve_context(context) do
    case context do
      :filter_map -> Context.FilterMap
      :table -> Context.Table
      :trace -> Context.Trace
      module when is_atom(module) -> module
    end
  end

  @doc """
  Macro for building a `Matcha.Pattern`.

  The `context` may be `:filter_map`, `:table`, `:trace`, or a `Matcha.Context` module.

  ## Examples

      iex> require Matcha
      ...> Matcha.pattern({x, y})
      #Matcha.Pattern<{:"$1", :"$2"}, context: filter_map>


  """
  defmacro pattern(context \\ @default_context_type, pattern) do
    context = resolve_context(context)
    rewrite = %Rewrite{env: __CALLER__, context: context, source: pattern}

    source =
      pattern
      |> expand_pattern(rewrite)
      |> rewrite_pattern(rewrite)
      |> Macro.escape(unquote: true)

    quote location: :keep do
      %Pattern{source: unquote(source), context: unquote(context)}
      |> Pattern.validate!()
    end
  end

  defp expand_pattern(match, rewrite) do
    {match, _env} = :elixir_expand.expand(match, Macro.Env.to_match(rewrite.env))
    match
  end

  defp rewrite_pattern(match, rewrite) do
    {rewrite, match} = Rewrite.rewrite_bindings(rewrite, match)
    Rewrite.rewrite_match(rewrite, match)
  end

  @doc """
  Macro for building a `Matcha.Spec`.

  The `context` may be `:filter_map`, `:table`, `:trace`, or a `Matcha.Context` module.

  ## Examples

      iex> require Matcha
      ...> Matcha.spec do
      ...>   {x, y, x} -> {y, x}
      ...> end
      #Matcha.Spec<[{{:"$1", :"$2", :"$1"}, [], [{{:"$2", :"$1"}}]}], context: filter_map>
  """
  defmacro spec(context \\ @default_context_type, _source = [do: clauses]) do
    context = resolve_context(context)
    rewrite = %Rewrite{env: __CALLER__, context: context, source: clauses}

    source =
      clauses
      |> expand_spec(rewrite)
      |> Enum.map(&normalize_clause(&1, rewrite))
      |> Enum.map(&rewrite_clause(&1, rewrite))
      |> Macro.escape(unquote: true)

    quote location: :keep do
      %Spec{source: unquote(source), context: unquote(context)}
      |> Spec.validate!()
    end
  end

  # defmacro spec(context \\ nil, _source = [do: clauses]) do
  #   spec = build_spec(__CALLER__, context, clauses)

  #   quote location: :keep do
  #     unquote(spec)
  #   end
  # end

  # def build_spec(env, context, clauses) do
  #   {context, type} = context_type(context)
  #   rewrite = %Rewrite{env: env, type: type, context: context, source: clauses}

  #   source =
  #     clauses
  #     |> expand_spec(rewrite)
  #     |> Enum.map(&normalize_clause(&1, rewrite))
  #     |> Enum.map(&rewrite_clause(&1, rewrite))
  #     |> Macro.escape(unquote: true)

  #   %Spec{source: source, type: type}
  #   |> Spec.validate!()
  # end

  defp expand_spec(clauses, rewrite) do
    elixir_ast =
      quote do
        # make special functions for this context available unadorned during expansion
        import unquote(rewrite.context), warn: false
        # mimic a `fn` definition for purposes of expanding clauses
        unquote({:fn, [], clauses})
      end

    {expansion, _env} = :elixir_expand.expand(elixir_ast, rewrite.env)

    {_, clauses} =
      Macro.prewalk(expansion, nil, fn
        {:fn, [], clauses}, nil -> {nil, clauses}
        other, clauses -> {other, clauses}
      end)

    clauses
  end

  defp normalize_clause({:->, _, [[head], body]}, _rewrite) do
    {match, conditions} = :elixir_utils.extract_guards(head)
    {match, conditions, List.wrap(body)}
  end

  defp normalize_clause(clause, rewrite) do
    raise Rewrite.Error,
      source: rewrite,
      details: "when normalizing clauses",
      problems: [
        error: "match spec clauses must be of arity 1, got: `#{Macro.to_string(clause)}`"
      ]
  end

  defp rewrite_clause({match, conditions, body}, rewrite) do
    {rewrite, match} = Rewrite.rewrite_bindings(rewrite, match)
    match = Rewrite.rewrite_match(rewrite, match)
    conditions = Rewrite.rewrite_conditions(rewrite, conditions)
    body = Rewrite.rewrite_body(rewrite, body)
    {match, conditions, body}
  end
end
