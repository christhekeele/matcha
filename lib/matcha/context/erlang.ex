defmodule Matcha.Context.Erlang do
  @moduledoc """
  Erlang functions and operators that any match specs can use in their bodies.

  ## Omissions

  This list aligns closely with what you would expect to be able to use in guards.
  However, erlang does not allow some guard-safe functions in match specs:

  - `:erlang.ceil/1`
  - `:erlang.floor/1`
  - `:erlang.is_function/2`
  - `:erlang.tuple_size/1`

  These functions are not allowed to be generated from Elixir source code by Matcha,
  because of compiler limitations. However, they can be used if constructing
  match specs by hand:

  - `:erlang.is_record/2`

  Additionally, these functions are documented as working in match specs,
  but do not seem to actually be allowed in all contexts:

  - `:erlang.binary_part/3`
  - `:erlang.byte_size/1`
  """

  @allowed_functions [
    # Used by or mapped to Elixir Kernel guards
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
    bit_size: 1,
    div: 2,
    element: 2,
    hd: 1,
    is_atom: 1,
    is_binary: 1,
    is_float: 1,
    is_function: 1,
    is_integer: 1,
    is_list: 1,
    is_map_key: 2,
    is_map: 1,
    is_number: 1,
    is_pid: 1,
    is_port: 1,
    is_reference: 1,
    is_tuple: 1,
    length: 1,
    map_size: 1,
    map_get: 2,
    node: 0,
    node: 1,
    not: 1,
    orelse: 2,
    self: 0,
    rem: 2,
    round: 1,
    tl: 1,
    trunc: 1,
    # Used by or mapped to Elixir Bitwise guards
    band: 2,
    bor: 2,
    bnot: 1,
    bsl: 2,
    bsr: 2,
    bxor: 2,
    # Not used by Elixir guards
    # TODO: add to rewrite suites
    and: 2,
    is_record: 3,
    or: 2,
    size: 1,
    xor: 2
  ]

  for {function, arity} <- @allowed_functions do
    @doc "All match specs can call `:erlang.#{function}/#{arity}`."
    def unquote(function)(unquote_splicing(Macro.generate_arguments(arity, __MODULE__))),
      do: :noop
  end
end
