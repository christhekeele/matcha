defmodule Matcha.Table.ETS do
  alias Matcha.Table
  alias Matcha.Table.ETS

  @type table :: atom() | :ets.tid()
  @type object :: tuple()

  @default_match_operation :all
  @match_operations Matcha.Table.ETS.Match.__info__(:functions) |> Keyword.keys()

  defmacro match(table, operation \\ @default_match_operation, pattern)
           when operation in @match_operations do
    quote location: :keep do
      require Matcha

      ETS.Match.unquote(operation)(unquote(table), Matcha.pattern(unquote(pattern)))
    end
  end

  @default_select_operation :all
  @select_operations Matcha.Table.ETS.Select.__info__(:functions) |> Keyword.keys()

  defmacro select(table, operation \\ @default_select_operation, spec)
           when operation in @select_operations do
    quote location: :keep do
      require Matcha.Table

      ETS.Select.unquote(operation)(unquote(table), Table.spec(unquote(spec)))
    end
  end
end
