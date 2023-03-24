defmodule Matcha.Table.ETS do
  alias Matcha.Table
  alias Matcha.Table.ETS

  @type table :: atom() | :ets.tid()
  @type object :: tuple()

  @default_match_operation :all
  @default_select_operation :all

  defmacro match(table, operation \\ @default_match_operation, pattern) do
    quote location: :keep do
      require Matcha

      case unquote(operation) do
        :all -> ETS.Match.all(unquote(table), Matcha.pattern(unquote(pattern)))
        :delete -> ETS.Match.delete(unquote(table), Matcha.pattern(unquote(pattern)))
        :object -> ETS.Match.object(unquote(table), Matcha.pattern(unquote(pattern)))
      end
    end
  end

  defmacro select(table, operation \\ @default_select_operation, spec) do
    quote location: :keep do
      require Matcha.Table

      case unquote(operation) do
        :all -> ETS.Select.all(unquote(table), Table.spec(unquote(spec)))
        :count -> ETS.Select.count(unquote(table), Table.spec(unquote(spec)))
        :delete -> ETS.Select.delete(unquote(table), Table.spec(unquote(spec)))
        :replace -> ETS.Select.replace(unquote(table), Table.spec(unquote(spec)))
        :reverse -> ETS.Select.reverse(unquote(table), Table.spec(unquote(spec)))
      end
    end
  end
end
