if Matcha.Helpers.application_loaded?(:mnesia) do
  defmodule Matcha.Table.Mnesia.Select do
    @moduledoc """
    Wrapper around [`:mnesia`](https://www.erlang.org/doc/man/mnesia) functions that accept `Matcha.Spec`s.
    """

    alias Matcha.Context.Table
    alias Matcha.Spec
    alias Matcha.Table.Mnesia

    @type operation :: :all

    @spec all(Mnesia.table(), Spec.t(), Mnesia.opts()) :: [tuple()]
    @doc """
    Selects and transforms all objects from `table` using `spec`.

    Accepted `opts`:

    - `lock:` defaults to `#{inspect(Mnesia.__default_lock__())}`

    This is a wrapper around `:mnesia.select/2` and `:mnesia.select/3`, consult those docs
    for more information.
    """
    def all(table, %Spec{context: Table} = spec, opts \\ []) do
      lock = Keyword.get(opts, :lock, Mnesia.__default_lock__())

      :mnesia.select(table, Spec.raw(spec), lock)
    end
  end
end
