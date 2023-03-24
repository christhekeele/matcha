defmodule Matcha.Table.ETS.Select do
  alias Matcha.Spec

  def all(table, spec = %Spec{context: Matcha.Context.Table}) do
    :ets.select(table, Spec.source(spec))
  end

  def count(table, spec = %Spec{context: Matcha.Context.Table}) do
    :ets.select_count(table, Spec.source(spec))
  end

  def delete(table, spec = %Spec{context: Matcha.Context.Table}) do
    :ets.select_delete(table, Spec.source(spec))
  end

  def replace(table, spec = %Spec{context: Matcha.Context.Table}) do
    :ets.select_replace(table, Spec.source(spec))
  end

  def reverse(table, spec = %Spec{context: Matcha.Context.Table}) do
    :ets.select_reverse(table, Spec.source(spec))
  end
end
