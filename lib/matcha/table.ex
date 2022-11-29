defmodule Matcha.Table.ETS do
  def matching(table, pattern = %Matcha.Pattern{}) do
    :ets.match(table, pattern.source)
  end

  defmacro fetch(table, block \\ []) do
    quote location: :keep do
      require Matcha

      unquote(__MODULE__).select(unquote(table), Matcha.spec(:table, unquote(block)))
    end
  end

  def select(table, spec = %Matcha.Spec{context: Matcha.Context.Table}) do
    :ets.select(table, spec.source)
  end
end
