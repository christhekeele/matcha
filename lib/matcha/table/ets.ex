defmodule Matcha.Table.ETS do
  @moduledoc """
  High-level macros for querying [`:ets`](https://www.erlang.org/doc/man/ets).

  The macros in this module build and execute match patterns/specs
  against [`:ets`](https://www.erlang.org/doc/man/ets) tables in one go.
  For more fine-grained usage, or if you are passing around or re-using
  the same pattern/spec, see the `Matcha.Table.ETS.Match` and
  `Matcha.Table.ETS.Select` modules.
  """

  @type table :: atom() | :ets.tid()
  @type object :: tuple()

  @default_match_operation :all
  @match_operations :functions |> Matcha.Table.ETS.Match.__info__() |> Keyword.keys()

  defmacro match(table, operation \\ @default_match_operation, pattern)
           when operation in @match_operations do
    quote location: :keep do
      require Matcha

      Matcha.Table.ETS.Match.unquote(operation)(
        unquote(table),
        Matcha.pattern(unquote(pattern))
      )
    end
  end

  @default_select_operation :all
  @select_operations :functions |> Matcha.Table.ETS.Select.__info__() |> Keyword.keys()

  defmacro select(table, operation \\ @default_select_operation, spec)
           when operation in @select_operations do
    quote location: :keep do
      require Matcha.Table

      Matcha.Table.ETS.Select.unquote(operation)(
        unquote(table),
        Table.spec(unquote(spec))
      )
    end
  end
end
