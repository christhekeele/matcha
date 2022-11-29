defmodule Matcha.Table do
  @doc """
  Builds a `Matcha.Spec` for table querying purposes.

  Shorthand for `Matcha.spec(:table, block)
  """
  defmacro spec(block) do
    quote location: :keep do
      require Matcha

      Matcha.spec(:table, unquote(block))
    end
  end
end
