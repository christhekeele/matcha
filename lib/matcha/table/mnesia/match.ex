if Matcha.Helpers.application_loaded?(:mnesia) do
  defmodule Matcha.Table.Mnesia.Match do
    def object(table, pattern = %Matcha.Pattern{}, lock_kind \\ :read) do
      :mnesia.match_object(table, pattern.source, lock_kind)
    end
  end
end
