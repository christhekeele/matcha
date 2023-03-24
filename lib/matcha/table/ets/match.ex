defmodule Matcha.Table.ETS.Match do
  alias Matcha.Pattern
  alias Matcha.Table.ETS

  @spec all(ETS.table(), Pattern.t()) :: [[term()]]
  def all(table, pattern = %Pattern{}) do
    :ets.match(table, Pattern.source(pattern))
  end

  @spec delete(ETS.table(), Pattern.t()) :: true
  def delete(table, pattern = %Pattern{}) do
    :ets.match_delete(table, Pattern.source(pattern))
  end

  @spec object(ETS.table(), Pattern.t()) :: [ETS.object()]
  def object(table, pattern = %Pattern{}) do
    :ets.match_object(table, Pattern.source(pattern))
  end
end
