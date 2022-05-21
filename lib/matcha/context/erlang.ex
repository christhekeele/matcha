defmodule Matcha.Context.Erlang do
  @moduledoc """
  Functions and operators that any match specs can use in their bodies.

  ### Limitations

  Neither `tuple_size/2` nor `is_record/2` are available here, though you'd expect them to be.
  For various reasons, Matcha cannot support `is_record/2` and erlang does not support `tuple_size/2`.

  ### Defined functions

  Note that this list corresponds to key functions in the `:erlang` module,
  or erlang operators, not their equivalents in Elixir's `Kernel` module (or the `Bitwise` guards).
  Allowed Elixir functions, operators, and macros composed of them are
  first expanded to erlang variants before they are looked up in this context.
  For example, `Kernel.send/2` expands to erlang's `!` operator, so is defined in this module as `!/2.`

  ### Further reading

  Aside from the above limitations, the common functions allowed in all match specs
  are just identical to those allowed in guards;
  so for an Elixir-ized, pre-erlang-ized expansion reference on
  what functions and operators you can use in any match spec, consult the docs for
  [what is allowed in guards](https://hexdocs.pm/elixir/patterns-and-guards.html#list-of-allowed-functions-and-operators).
  For an erlang reference, see
  [the tracing match spec docs](https://www.erlang.org/doc/apps/erts/match_spec.html#functions-allowed-in-all-types-of-match-specifications).

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
    # binary_part: 3, # currently broken in erlang
    bit_size: 1,
    # byte_size: 1, # currently broken in erlang
    # ceil: 1, # not supported
    div: 2,
    element: 2,
    # floor: 1, # not supported
    hd: 1,
    # cont
    is_atom: 1,
    is_binary: 1,
    is_integer: 1,
    is_number: 1,
    map_get: 2,
    not: 1,
    orelse: 2
  ]
  for {function, arity} <- @allowed_functions do
    @doc "All match specs can call `:erlang.#{function}/#{arity}`."
    def unquote(function)(unquote_splicing(Macro.generate_arguments(arity, __MODULE__))),
      do: :noop
  end
end
