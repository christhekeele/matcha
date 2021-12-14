defmodule Matcha.Context.Common do
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

  for {function, arity} <-
        Keyword.get(:erlang.module_info(), :exports) ++ [andalso: 2, orelse: 2],
      :erl_internal.arith_op(function, arity) or :erl_internal.bool_op(function, arity) or
        :erl_internal.comp_op(function, arity) or :erl_internal.guard_bif(function, arity) or
        :erl_internal.send_op(function, arity) or {:andalso, 2} == {function, arity} or
        {:orelse, 2} == {function, arity} do
    # TODO: for some reason the only guard not allowed in match specs is `tuple_size/1`.
    # It is unclear to me why this is the case; though it is probably rarely used since
    #  destructuring tuples of different sizes in different clauses is far more idiomatic.

    # TODO: if you try to define `is_record/2` (supported in match specs for literals in the second arity),
    #  you get the compilation error:
    #    (CompileError) cannot define def is_record/2
    #    due to compatibility issues with the Erlang compiler (it is a known limitation)
    # While a call to the `Record.is_record/2` guard is expanded differently,
    #  and does not use erlang's version,
    #  whose expansion could be theoretically validly used in its place,
    #  its expansion calls the `tuple_size/1` guard,
    #  which as documented in the TODO above is not allowed in match specs.
    # Ultimately this means that there is no way for Matcha to support `is_record/2`.
    # What a headache.
    unless (function == :tuple_size and arity == 1) or (function == :is_record and arity == 2) do
      @doc "All match specs can call erlang's `#{function}/#{arity}`."
      def unquote(function)(unquote_splicing(Macro.generate_arguments(arity, __MODULE__))),
        do: :noop
    end
  end
end
