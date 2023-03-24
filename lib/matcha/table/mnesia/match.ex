if Matcha.Helpers.application_loaded?(:mnesia) do
  defmodule Matcha.Table.Mnesia.Match do
    alias Matcha.Pattern
    alias Matcha.Table.Mnesia

    @type operation :: :object

    @spec object(Mnesia.table(), Pattern.t(), Mnesia.opts()) :: [tuple()]
    def object(table, pattern = %Pattern{}, opts \\ []) do
      lock = Keyword.get(opts, :lock, Mnesia.__default_lock__())

      :mnesia.match_object(table, Pattern.source(pattern), lock)
    end
  end
end
