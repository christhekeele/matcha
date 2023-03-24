if Matcha.Helpers.application_loaded?(:mnesia) do
  defmodule Matcha.Table.Mnesia.Match do
    alias Matcha.Pattern

    alias Matcha.Table.Mnesia

    @spec object(Mnesia.table(), Pattern.t(), Mnesia.lock_kind()) :: [tuple()]
    def object(table, pattern = %Pattern{}, lock_kind \\ :read) do
      :mnesia.match_object(table, Pattern.source(pattern), lock_kind)
    end
  end
end
