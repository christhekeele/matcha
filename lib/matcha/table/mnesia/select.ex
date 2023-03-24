if Matcha.Helpers.application_loaded?(:mnesia) do
  defmodule Matcha.Table.Mnesia.Select do
    alias Matcha.Spec
    alias Matcha.Table.Mnesia

    @spec all(Mnesia.table(), Spec.t(), Mnesia.lock_kind()) :: [tuple()]
    def all(
          table,
          spec = %Spec{context: Matcha.Context.Table},
          lock_kind \\ Mnesia.__default_lock_kind__()
        ) do
      :mnesia.select(table, Spec.source(spec), lock_kind)
    end
  end
end
