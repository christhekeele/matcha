if Matcha.Helpers.application_loaded?(:mnesia) do
  defmodule Matcha.Table.Mnesia.Select do
    alias Matcha.Spec
    alias Matcha.Context.Table
    alias Matcha.Table.Mnesia

    @type operation :: :all

    @spec all(Mnesia.table(), Spec.t(), Mnesia.opts()) :: [tuple()]
    def all(table, spec = %Spec{context: Table}, opts \\ []) do
      lock = Keyword.get(opts, :lock, Mnesia.__default_lock__())

      :mnesia.select(table, Spec.source(spec), lock)
    end
  end
end
