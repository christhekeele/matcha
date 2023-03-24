defmodule Matcha.Table.ETS.Select do
  alias Matcha.Spec
  alias Matcha.Context.Table
  alias Matcha.Table.ETS

  @type operation :: :all | :count | :delete | :replace | :reverse

  @spec all(ETS.table(), Spec.t()) :: [term()]
  def all(table, spec = %Spec{context: Table}) do
    :ets.select(table, Spec.source(spec))
  end

  @spec count(ETS.table(), Spec.t()) :: non_neg_integer()
  def count(table, spec = %Spec{context: Table}) do
    :ets.select_count(table, Spec.source(spec))
  end

  @spec delete(ETS.table(), Spec.t()) :: non_neg_integer()
  def delete(table, spec = %Spec{context: Table}) do
    :ets.select_delete(table, Spec.source(spec))
  end

  @spec replace(ETS.table(), Spec.t()) :: non_neg_integer()
  def replace(table, spec = %Spec{context: Table}) do
    :ets.select_replace(table, Spec.source(spec))
  end

  @spec reverse(ETS.table(), Spec.t()) :: [term()]
  def reverse(table, spec = %Spec{context: Table}) do
    :ets.select_reverse(table, Spec.source(spec))
  end
end
