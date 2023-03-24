if Matcha.Helpers.application_loaded?(:mnesia) do
  defmodule Matcha.Table.Mnesia do
    alias Matcha.Table
    alias Matcha.Table.Mnesia

    @type table :: atom()
    @type lock_kind :: :read | :sticky_write | :write

    @default_lock_kind :read
    @compile {:inline, __default_lock_kind__: 0}
    def __default_lock_kind__, do: @default_lock_kind

    defmacro match_object(table, lock_kind \\ @default_lock_kind, pattern) do
      quote location: :keep do
        require Matcha

        Mnesia.Match.object(unquote(table), Matcha.pattern(unquote(pattern)), unquote(lock_kind))
      end
    end

    defmacro select(table, lock_kind \\ @default_lock_kind, spec) do
      quote location: :keep do
        require Matcha.Table

        Mnesia.Select.all(unquote(table), Matcha.spec(unquote(spec)), unquote(lock_kind))
      end
    end
  end
end
