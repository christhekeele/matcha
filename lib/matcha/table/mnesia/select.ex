if Matcha.Helpers.application_loaded?(:mnesia) do
  defmodule Matcha.Table.Mnesia.Select do
    alias Matcha.Spec

    def all(table, spec = %Spec{context: Matcha.Context.Table}, lock_kind \\ :read) do
      :mnesia.select(table, Spec.source(spec), lock_kind)
    end
  end
end
