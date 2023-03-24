defmodule Matcha.Table.ETS do
  alias Matcha.Table
  alias Matcha.Table.ETS

  @type table :: atom() | :ets.tid()
  @type object :: tuple()

  defmacro match(table, pattern) do
    quote location: :keep do
      require Matcha

      ETS.Match.all(unquote(table), Matcha.pattern(unquote(pattern)))
    end
  end

  defmacro select(table, spec) do
    quote location: :keep do
      require Matcha.Table

      ETS.Select.all(unquote(table), Table.spec(unquote(spec)))
    end
  end
end
