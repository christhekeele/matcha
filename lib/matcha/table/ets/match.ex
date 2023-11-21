defmodule Matcha.Table.ETS.Match do
  @moduledoc """
  Wrapper around [`:ets`](https://www.erlang.org/doc/man/ets) functions that accept `Matcha.Pattern`s.
  """

  alias Matcha.Pattern
  alias Matcha.Table.ETS

  @type operation :: :all | :delete | :object

  @spec all(ETS.table(), Pattern.t()) :: [[term()]]
  def all(table, pattern = %Pattern{}) do
    :ets.match(table, Pattern.raw(pattern))
  end

  @spec delete(ETS.table(), Pattern.t()) :: true
  def delete(table, pattern = %Pattern{}) do
    :ets.match_delete(table, Pattern.raw(pattern))
  end

  @spec object(ETS.table(), Pattern.t()) :: [ETS.object()]
  def object(table, pattern = %Pattern{}) do
    :ets.match_object(table, Pattern.raw(pattern))
  end
end
