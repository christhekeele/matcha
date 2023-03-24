defmodule Matcha.Context.Common do
  @moduledoc """
  Functions and operators that any match spec can use.
  """

  defmacro target, do: Matcha.Source.__target_matcher__()

  defmacro bindings, do: Matcha.Source.__bindings_matcher__()
end
