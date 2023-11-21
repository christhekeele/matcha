if Matcha.Helpers.application_loaded?(:mnesia) do
  defmodule Matcha.Table.Mnesia do
    @moduledoc """
    High-level macros for querying [`:mnesia`](https://www.erlang.org/doc/man/mnesia).

    The macros in this module build and execute match patterns/specs
    against [`:mnesia`](https://www.erlang.org/doc/man/mnesia) tables in one go.
    For more fine-grained usage, or if you are passing around or re-using
    the same pattern/spec, see the `Matcha.Table.Mnesia.Match` and
    `Matcha.Table.Mnesia.Select` modules.
    """

    @default_lock :read
    def __default_lock__, do: @default_lock

    @type table :: atom()
    @type lock :: :read | :sticky_write | :write
    @type default_lock :: unquote(@default_lock)
    @type opts :: [{:lock, lock}]

    @doc """
    Returns all objects from `table` matching `pattern`.

    Accepted `opts`:

    - `lock:` defaults to `#{inspect(@default_lock)}`

    This is a wrapper around `Matcha.Table.Mnesia.Match.objects/3`, consult those docs
    for more information.

    ### Examples

        director = "Steven Spielberg"
        composer = "John Williams"

        require Matcha.Table.Mnesia
        Matcha.Table.Mnesia.match(table, {Movie, _id, _title, _year, ^director, ^composer})
        #=> [
          {Movie, "tt0073195", "Jaws", 1975, "Steven Spielberg", "John Williams"},
          {Movie, "tt0082971", "Raiders of the Lost Ark", 1981, "Steven Spielberg", "John Williams"},
          # ...
        ]
    """
    defmacro match(table, pattern, opts \\ []) do
      quote location: :keep do
        require Matcha

        Matcha.Table.Mnesia.Match.objects(
          unquote(table),
          Matcha.pattern(unquote(pattern)),
          unquote(opts)
        )
      end
    end

    @doc """
    Selects and transforms all objects from `table` using `spec`.

    Accepted `opts`:

    - `lock:` defaults to `#{inspect(@default_lock)}`

    This is a wrapper around `Matcha.Table.Mnesia.Select.all/3`, consult those docs
    for more information.

    ### Examples

        director = "Steven Spielberg"
        composer = "John Williams"

        require Matcha.Table.Mnesia
        Matcha.Table.Mnesia.select(table) do
          {_, _id, title, ^director, ^composer} when year > 1980
            -> title
        end
        #=> [
          "Raiders of the Lost Ark",
          "E.T. the Extra-Terrestrial",
          # ...
        ]
    """
    defmacro select(table, opts \\ [], spec) do
      quote location: :keep do
        require Matcha.Table

        Matcha.Table.Mnesia.Select.all(
          unquote(table),
          Table.spec(unquote(spec)),
          unquote(opts)
        )
      end
    end
  end
end
