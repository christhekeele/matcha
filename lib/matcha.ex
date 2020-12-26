defmodule Matcha do
  alias Matcha.Context
  alias Matcha.Rewrite
  alias Matcha.Spec
  alias Matcha.Pattern

  @type type :: :table | :trace
  @type context :: atom | nil

  @type problems :: [problem]
  @type problem :: {:error | :warning, String.t()}

  # TODO
  # defmacro sigil_m, do: :noop
  # defmacro sigil_M, do: :noop

  @doc """
  Builds a `Matcha.Pattern`.
  """
  defmacro pattern(type \\ nil, do: clauses) do
    {context, type} = contextualize_type(type)

    source =
      clauses
      |> pattern(__CALLER__, type, context)
      |> Macro.escape(unquote: true)

    quote location: :keep do
      %Pattern{source: unquote(source), type: unquote(type)}
      |> Pattern.validate!()
    end
  end

  @doc """
  Builds a `Matcha.Spec`.
  """
  defmacro spec(type \\ nil, do: clauses) do
    {context, type} = contextualize_type(type)

    source =
      clauses
      |> spec(__CALLER__, type, context)
      |> Macro.escape(unquote: true)

    quote location: :keep do
      %Spec{source: unquote(source), type: unquote(type)}
      |> Spec.validate!()
    end
  end

  @spec contextualize_type(type | context | nil) :: {context, type}
  defp contextualize_type(type) do
    case type do
      :table -> {Context.Table, type}
      :trace -> {Context.Trace, type}
      nil -> {nil, :table}
      module when is_atom(module) -> {module, module.__type__()}
    end
  end

  @doc false
  def spec(spec, env, type, context \\ nil) do
    rewrite = %Rewrite{env: env, type: type, context: context}

    expand_spec(spec, rewrite)
    |> Enum.map(&normalize_clause/1)
    |> Enum.map(&rewrite_clause(&1, rewrite))
  end

  defp expand_spec(spec, rewrite) do
    expansion =
      if rewrite.context do
        quote do
          import unquote(rewrite.context), warn: false
          unquote({:fn, [], spec})
        end
      else
        {:fn, [], spec}
      end

    {ast, _env} = :elixir_expand.expand(expansion, rewrite.env)

    {_, clauses} =
      Macro.prewalk(ast, nil, fn
        {:fn, [], clauses} = fun, nil -> {fun, clauses}
        other, clauses -> {other, clauses}
      end)

    clauses
  end

  defp normalize_clause({:->, _, [[head], body]}) do
    {match, conditions} = :elixir_utils.extract_guards(head)
    {match, conditions, List.wrap(body)}
  end

  defp normalize_clause(clause) do
    raise Rewrite.Error,
      message: "match spec clauses must be of arity 1, got: `#{Macro.to_string(clause)}`"
  end

  defp rewrite_clause({match, conditions, body}, rewrite) do
    {rewrite, match} = Rewrite.rewrite_bindings(rewrite, match)
    match = Rewrite.rewrite_match(rewrite, match)
    conditions = Rewrite.rewrite_conditions(rewrite, conditions)
    body = Rewrite.rewrite_body(rewrite, body)
    {match, conditions, body}
  end

  @doc false
  def pattern(pattern, env, type, context \\ nil) do
    {pattern, env} = expand_pattern(pattern, env)
    rewrite = %Rewrite{env: env, type: type, context: context}
    rewrite_pattern(pattern, rewrite)
  end

  defp expand_pattern(pattern, env) do
    {pattern, env} = :elixir_expand.expand(pattern, %{env | context: :match})
    {pattern, env}
  end

  defp rewrite_pattern(match, rewrite) do
    {rewrite, match} = Rewrite.rewrite_bindings(rewrite, match)
    Rewrite.rewrite_match(rewrite, match)
  end
end
