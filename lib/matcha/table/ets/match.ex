defmodule Matcha.Table.ETS.Match do
  alias Matcha.Pattern

  def all(table, pattern = %Pattern{}) do
    :ets.match(table, Pattern.source(pattern))
  end

  def delete(table, pattern = %Pattern{}) do
    :ets.match_delete(table, Pattern.source(pattern))
  end

  def object(table, pattern = %Pattern{}) do
    :ets.match_object(table, Pattern.source(pattern))
  end
end
