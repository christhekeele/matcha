defmodule Matcha.Table.Mnesia do
  alias Matcha.Table
  alias Matcha.Table.Mnesia

  defmacro match_object(table, lock_kind \\ :read, pattern) do
    quote location: :keep do
      require Matcha

      Mnesia.Match.object(unquote(table), Matcha.pattern(unquote(pattern)), unquote(lock_kind))
    end
  end

  defmacro select(table, lock_kind \\ :read, spec) do
    quote location: :keep do
      require Matcha.Table

      Mnesia.Select.all(unquote(table), Table.spec(unquote(spec)), unquote(lock_kind))
    end
  end
end
