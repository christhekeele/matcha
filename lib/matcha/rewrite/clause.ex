defmodule Matcha.Rewrite.Clause do
  @moduledoc """
  Rewrites expanded Elixir clauses into Erlang match specification entries.
  """

  alias Matcha.Rewrite

  defstruct [:match, guards: [], body: []]

  def new({:->, _, [[head], body]}, _rewrite) do
    {match, guards} = :elixir_utils.extract_guards(head)

    %__MODULE__{
      match: match,
      guards: guards,
      body: [body]
    }
  end

  def new(clause, rewrite) do
    raise Rewrite.Error,
      source: rewrite,
      details: "when rewriting clauses",
      problems: [
        error: "match spec clauses must be of arity 1, got: `#{Macro.to_string(clause)}`"
      ]
  end

  def rewrite(%__MODULE__{} = clause, rewrite) do
    {rewrite, match} = Rewrite.Bindings.rewrite(rewrite, clause.match)
    match = Rewrite.Match.rewrite(rewrite, match)

    guards = Rewrite.Guards.rewrite(clause.guards, rewrite)

    body = rewrite_body(rewrite, clause.body)
    {{match, guards, body}, rewrite.bindings.vars}
  end

  @spec rewrite_body(Rewrite.t(), Macro.t()) :: Macro.t()
  def rewrite_body(rewrite, ast)

  def rewrite_body(rewrite, [{:__block__, _, body}]) do
    rewrite_body(rewrite, body)
  end

  def rewrite_body(rewrite, body) do
    Rewrite.Expression.rewrite(body, rewrite)
  end
end
