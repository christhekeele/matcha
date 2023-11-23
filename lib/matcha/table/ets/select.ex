defmodule Matcha.Table.ETS.Select do
  @moduledoc """
  Wrapper around [`:ets`](https://www.erlang.org/doc/man/ets) functions that accept `Matcha.Spec`s.
  """

  alias Matcha.Context.Table
  alias Matcha.Spec
  alias Matcha.Table.ETS

  @type operation :: :all | :count | :delete | :replace | :reverse

  @spec all(ETS.table(), Spec.t()) :: [term()]
  def all(table, %Spec{context: Table} = spec) do
    :ets.select(table, Spec.raw(spec))
  end

  @spec count(ETS.table(), Spec.t()) :: non_neg_integer()
  def count(table, %Spec{context: Table} = spec) do
    :ets.select_count(table, Spec.raw(spec))
  end

  @spec delete(ETS.table(), Spec.t()) :: non_neg_integer()
  def delete(table, %Spec{context: Table} = spec) do
    :ets.select_delete(table, Spec.raw(spec))
  end

  @spec replace(ETS.table(), Spec.t()) :: non_neg_integer()
  def replace(table, %Spec{context: Table} = spec) do
    :ets.select_replace(table, Spec.raw(spec))
  end

  @spec reverse(ETS.table(), Spec.t()) :: [term()]
  def reverse(table, %Spec{context: Table} = spec) do
    :ets.select_reverse(table, Spec.raw(spec))
  end
end
