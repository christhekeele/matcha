defmodule Matcha.Table.ETS do
  alias Matcha.Table
  alias Matcha.Table.ETS

  defmacro match(table, pattern) do
    quote location: :keep do
      require Matcha

      ETS.Match.all(unquote(table), Matcha.pattern(unquote(pattern)))
    end
  end

  defmacro select(table, operation \\ :all, spec) do
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
