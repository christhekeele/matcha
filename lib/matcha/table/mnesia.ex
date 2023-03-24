if Matcha.Helpers.application_loaded?(:mnesia) do
  defmodule Matcha.Table.Mnesia do
    alias Matcha.Table
    alias Matcha.Table.Mnesia

    @type table :: atom()
    @type lock :: :read | :sticky_write | :write
    @type opts :: [{:lock, lock}]

    @default_lock :read
    @compile {:inline, __default_lock__: 0}
    def __default_lock__, do: @default_lock

    defmacro match_object(table, pattern, opts \\ []) do
      quote location: :keep do
        require Matcha

        Mnesia.Match.object(unquote(table), Matcha.pattern(unquote(pattern)), unquote(opts))
      end
    end

    defmacro select(table, spec, opts \\ []) do
      quote location: :keep do
        require Matcha.Table

        Mnesia.Select.all(unquote(table), Table.spec(unquote(spec)), unquote(opts))
      end
    end
  end
end
