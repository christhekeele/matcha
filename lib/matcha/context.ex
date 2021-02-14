defmodule Matcha.Context do
  @moduledoc false

  alias Matcha.Source

  @type t :: atom | nil

  @callback __type__() :: Source.type()

  # TODO: use as functional context when we can define is_record/2, today we get:
  #    (CompileError) cannot define def is_record/2
  #    due to compatibility issues with the Erlang compiler (it is a known limitation)
  #
  # for {function, arity} <- Keyword.get(:erlang.module_info(), :exports),
  #     :erl_internal.arith_op(function, arity) or :erl_internal.bool_op(function, arity) or
  #       :erl_internal.comp_op(function, arity) or :erl_internal.guard_bif(function, arity) or
  #       :erl_internal.send_op(function, arity) or {:andalso, 2} == {function, arity} or
  #       {:orelse, 2} == {function, arity} do
  #   def unquote(function)(unquote_splicing(Macro.generate_arguments(arity, __MODULE__))),
  #     do: :noop
  # end
end
