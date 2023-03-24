defmodule Matcha.Table do
  @doc """
  Builds a `Matcha.Spec` for table querying purposes.

  Shorthand for `Matcha.spec(:table, spec)
  """
  defmacro spec(spec) do
    quote location: :keep do
      require Matcha

      Matcha.spec(:table, unquote(spec))
    end
  end
end
