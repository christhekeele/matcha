defmodule Matcha.Rewrite.Kernel do
  @moduledoc """
  Replacements for Kernel functions when rewriting Elixir into match specs.

  These are versions that play nicer with Erlang's match spec limitations.
  """

  import Kernel, except: [is_boolean: 1]

  @doc """
  Re-implements `Kernel.is_boolean/1`.

  The original simply calls out to `:erlang.is_boolean/1`, which is
  not allowed in match specs. Instead, we re-implement it in terms of
  things that are.
  """
  defguard is_boolean(value)
           when is_atom(value) and (value == true or value == false)
end
