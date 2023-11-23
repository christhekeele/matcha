if Matcha.Helpers.application_loaded?(:mnesia) do
  defmodule Matcha.Table.Mnesia.Match do
    @moduledoc """
    Wrapper around [`:mnesia`](https://www.erlang.org/doc/man/mnesia) functions that accept `Matcha.Pattern`s.
    """

    alias Matcha.Pattern
    alias Matcha.Table.Mnesia

    @type operation :: :object

    @spec objects(Pattern.t()) :: [tuple()]
    @doc """
    Returns all objects from a table matching `pattern`.

    The [`:mnesia`](https://www.erlang.org/doc/man/mnesia) table that will be queried
    corresponds to the first element of the provided `pattern`.

    This is a wrapper around `:mnesia.match_object/1`, consult those docs
    for more information.
    """
    def objects(%Pattern{} = pattern) do
      :mnesia.match_object(Pattern.raw(pattern))
    end

    @spec objects(Mnesia.table(), Pattern.t(), Mnesia.opts()) :: [tuple()]
    @doc """
    Returns all objects from `table` matching `pattern`.

    Accepted `opts`:

    - `lock:` defaults to `#{inspect(Mnesia.__default_lock__())}`

    This is a wrapper around `:mnesia.match_object/3`, consult those docs
    for more information.
    """
    def objects(table, %Pattern{} = pattern, opts \\ []) do
      lock = Keyword.get(opts, :lock, Mnesia.__default_lock__())

      :mnesia.match_object(table, Pattern.raw(pattern), lock)
    end
  end
end
