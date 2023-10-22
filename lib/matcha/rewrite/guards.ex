defmodule Matcha.Rewrite.Guards do
  alias Matcha.Rewrite

  @spec rewrite(Macro.t(), Rewrite.t()) :: Macro.t()
  def rewrite(guards, rewrite) do
    guards
    |> Enum.map(&Rewrite.Expression.rewrite(&1, rewrite))
    |> merge_guards(rewrite)
  end

  def merge_guards(guards, rewrite) do
    extra_guard =
      for extra_guard <- rewrite.guards, reduce: [] do
        [] -> extra_guard
        guard -> {:andalso, guard, extra_guard}
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
