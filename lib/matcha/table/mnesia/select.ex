if Matcha.Helpers.application_loaded?(:mnesia) do
  defmodule Matcha.Table.Mnesia.Select do
    def all(table, spec = %Matcha.Spec{context: Matcha.Context.Table}, lock_kind \\ :read) do
      :mnesia.select(table, spec.source, lock_kind)
    end
  end
end
