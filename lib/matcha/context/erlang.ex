defmodule Matcha.Context.Erlang do
  @moduledoc moduledoc

  moduledoc = """
  Erlang functions and operators that any match specs can use in their bodies.

  ## Omissions

  This list aligns closely with what you would expect to be able to use in guards.
  However, Erlang does not allow some guard-safe functions in match specs:

  - `:erlang.is_record/2`
  """

  # TODO: Once Erlang/OTP 26 is the minimum supported version,
  #       we can metaprogram this as we used to try to do and 26 now does, via
  #       https://github.com/erlang/otp/pull/7046/files#diff-32b3cd3e6c0d949335e0d3da944dd750e07eeee7f2f8613e6865a7ae70b33e48R1167-R1173
  #       or how Elixir does, via
  #       https://github.com/elixir-lang/elixir/blob/f4b05d178d7b9bb5356beae7ef8e01c32324d476/lib/elixir/src/elixir_utils.erl#L24-L37

  moduledoc =
    if Matcha.Helpers.erlang_version() < 25 do
      moduledoc <>
        """

        These functions only work in match specs in Erlang/OTP >= 25,
        and are not available to you in Erlang/OTP #{Matcha.Helpers.erlang_version()}:

        - `:erlang.binary_part/2`
        - `:erlang.binary_part/3`
        - `:erlang.byte_size/1`
        """
    else
      moduledoc
    end

  moduledoc =
    if Matcha.Helpers.erlang_version() < 26 do
      moduledoc <>
        """

        These functions only work in match specs in Erlang/OTP >= 26,
        and are not available to you in Erlang/OTP #{Matcha.Helpers.erlang_version()}:

        - `:erlang.ceil/1`
        - `:erlang.floor/1`
        - `:erlang.is_function/2`
        - `:erlang.tuple_size/1`
        """
    else
      moduledoc
    end

  @allowed_short_circuit_expressions [
    andalso: 2,
    orelse: 2
  ]

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
    and: 2,
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
    is_record: 3,
    is_reference: 1,
    is_tuple: 1,
    length: 1,
    map_size: 1,
    map_get: 2,
    node: 0,
    node: 1,
    not: 1,
    or: 2,
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
    # No Elixir equivalent
    size: 1,
    xor: 2
  ]

  if Matcha.Helpers.erlang_version() >= 25 do
    @allowed_functions @allowed_functions ++ [binary_part: 2, binary_part: 3]
    @allowed_functions @allowed_functions ++ [byte_size: 1]
  end

  if Matcha.Helpers.erlang_version() >= 26 do
    @allowed_functions @allowed_functions ++ [ceil: 1, floor: 1]
    @allowed_functions @allowed_functions ++ [is_function: 2]
    @allowed_functions @allowed_functions ++ [tuple_size: 1]
  end

  for {function, arity} <- @allowed_functions do
    @doc "All match specs can call `:erlang.#{function}/#{arity}`."
    def unquote(function)(unquote_splicing(Macro.generate_arguments(arity, __MODULE__))), do: :noop
  end

  for {function, arity} <- @allowed_short_circuit_expressions do
    @doc "All match specs can call the `#{function}/#{arity}` [short-circuit expression](https://www.erlang.org/doc/reference_manual/expressions.html#short-circuit-expressions)."
    def unquote(function)(unquote_splicing(Macro.generate_arguments(arity, __MODULE__))), do: :noop
  end
end
