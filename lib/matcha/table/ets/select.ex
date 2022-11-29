defmodule Matcha.Table.ETS.Select do
  def all(table, spec = %Matcha.Spec{context: Matcha.Context.Table}) do
    :ets.select(table, spec.source)
  end

  def count(table, spec = %Matcha.Spec{context: Matcha.Context.Table}) do
    :ets.select_count(table, spec.source)
  end

  def delete(table, spec = %Matcha.Spec{context: Matcha.Context.Table}) do
    :ets.select_delete(table, spec.source)
  end

  def replace(table, spec = %Matcha.Spec{context: Matcha.Context.Table}) do
    :ets.select_replace(table, spec.source)
  end

  def reverse(table, spec = %Matcha.Spec{context: Matcha.Context.Table}) do
    :ets.select_reverse(table, spec.source)
  end
end
