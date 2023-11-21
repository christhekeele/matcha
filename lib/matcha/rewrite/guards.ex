defmodule Matcha.Rewrite.Guards do
  @moduledoc """
  Rewrites expanded Elixir guard lists into Erlang match spec guard lists.
  """

  alias Matcha.Rewrite

  @spec rewrite(Macro.t(), Rewrite.t()) :: Macro.t()
  def rewrite(guards, rewrite) do
    guards
    |> Enum.map(&Rewrite.Expression.rewrite(&1, rewrite))
    |> merge_guards(rewrite)
  end

  def merge_guards(guards, rewrite) do
    extra_guard =
      for extra_guard <- :lists.reverse(rewrite.guards), reduce: [] do
        [] -> Rewrite.Expression.rewrite_literals(extra_guard, rewrite)
        guard -> {:andalso, guard, Rewrite.Expression.rewrite_literals(extra_guard, rewrite)}
      end

    case {guards, extra_guard} do
      {[], []} ->
        []

      {guards, []} ->
        guards

      {[], extra_guard} ->
        [extra_guard]

      {guards, extra_guard} ->
        for guard <- guards do
          {:andalso, guard, extra_guard}
        end
    end
  end
end
