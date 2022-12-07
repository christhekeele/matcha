defmodule Matcha.Table.ETS.Match do
  def all(table, pattern = %Matcha.Pattern{}) do
    :ets.match(table, pattern.source)
  end

  def delete(table, pattern = %Matcha.Pattern{}) do
    :ets.match_delete(table, pattern.source)
  end

  def object(table, pattern = %Matcha.Pattern{}) do
    :ets.match_object(table, pattern.source)
  end
end
