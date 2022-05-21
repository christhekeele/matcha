defmodule Matcha.Context.Erlang do
  @moduledoc """
  Erlang functions and operators that any match specs can use in their bodies.
  """

  @allowed_functions [
    -: 1,
    -: 2,
    "/=": 2,
    "=/=": 2,
    *: 2,
    /: 2,
    +: 1,
    +: 2,
    <: 2,
    "=<": 2,
    ==: 2,
    "=:=": 2,
    >: 2,
    >=: 2,
    abs: 1,
    andalso: 2,
    # binary_part: 3, # currently broken in erlang match specs despite being documented as supported
    bit_size: 1,
    # byte_size: 1, # currently broken in erlang match specs despite being documented as supported
    # ceil: 1, # guard not supported in erlang match specs
    div: 2,
    element: 2,
    # floor: 1, # guard not supported in erlang match specs
    hd: 1,
    # cont
    is_atom: 1,
    is_binary: 1,
    is_integer: 1,
    is_number: 1,
    is_record: 1,
    map_get: 2,
    not: 1,
    orelse: 2
    # tuple_size: 2 # guard not supported in erlang match specs
  ]
  for {function, arity} <- @allowed_functions do
    @doc "All match specs can call `:erlang.#{function}/#{arity}`."
    def unquote(function)(unquote_splicing(Macro.generate_arguments(arity, __MODULE__))),
      do: :noop
  end
end
