defmodule Matcha.Rewrite.Calls do
  @moduledoc """
  Rewrites expanded Elixir function calls into Erlang match specification tuple-calls.
  """

  alias Matcha.Rewrite
  alias Matcha.Context
  import Matcha.Rewrite.AST, only: :macros

  @spec rewrite(Macro.t(), Rewrite.t()) :: Macro.t()
  def rewrite(ast, rewrite) do
    do_rewrite(ast, rewrite)
  end

  @spec do_rewrite(Macro.t(), Rewrite.t()) :: Macro.t()
  defp do_rewrite(ast, rewrite)

  defp do_rewrite(
         {{:., _, [module, function]}, _, args} = call,
         %Rewrite{context: context} = rewrite
       )
       when is_remote_call(call) and module == context do
    args = do_rewrite(args, rewrite)

    # Permitted calls to special functions unique to specific contexts can be looked up from the spec's context module.
    if {function, length(args)} in module.__info__(:functions) do
      List.to_tuple([function | args])
    else
      raise_invalid_call_error!(rewrite, {module, function, args})
    end
  end

  defp do_rewrite({{:., _, [:erlang = module, function]}, _, args} = call, rewrite)
       when is_remote_call(call) do
    args = do_rewrite(args, rewrite)

    # Permitted calls to unqualified functions and operators that appear
    #  to reference the `:erlang` kernel module post expansion.
    # They are intercepted here and looked up instead from the Erlang context before becoming an instruction.
    if {function, length(args)} in Context.Erlang.__info__(:functions) do
      List.to_tuple([function | args])
    else
      raise_invalid_call_error!(rewrite, {module, function, args})
    end
  end

  defp do_rewrite(
         {{:., _, [module, function]}, _, args} = call,
         rewrite = %Rewrite{}
       )
       when is_remote_call(call) do
    raise_invalid_call_error!(rewrite, {module, function, args})
  end

  defp do_rewrite([head | tail] = list, rewrite) when is_list(list) do
    [do_rewrite(head, rewrite) | do_rewrite(tail, rewrite)]
  end

  defp do_rewrite([] = list, _rewrite) when is_list(list) do
    []
  end

  defp do_rewrite(tuple, rewrite) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> do_rewrite(rewrite)
    |> List.to_tuple()
  end

  defp do_rewrite(ast, _rewrite) do
    #  when is_atom(ast) or is_number(ast) or is_bitstring(ast) or is_map(ast) do
    ast
  end

  @spec raise_invalid_call_error!(Rewrite.t(), Rewrite.Bindings.var_ast()) :: no_return()
  defp raise_invalid_call_error!(rewrite, call)

  if Matcha.Helpers.erlang_version() < 25 do
    for {erlang_25_function, erlang_25_arity} <- [binary_part: 2, binary_part: 3, byte_size: 1] do
      defp raise_invalid_call_error!(rewrite = %Rewrite{}, {module, function, args})
           when module == :erlang and
                  function == unquote(erlang_25_function) and
                  length(args) == unquote(erlang_25_arity) do
        raise Rewrite.Error,
          source: rewrite,
          details: "unsupported function call",
          problems: [
            error:
              "Erlang/OTP #{Matcha.Helpers.erlang_version()} does not support calling" <>
                " `#{inspect(module)}.#{function}/#{length(args)}`" <>
                " in match specs, you must be using Erlang/OTP 25 or greater"
          ]
      end
    end
  end

  defp raise_invalid_call_error!(rewrite = %Rewrite{}, {module, function, args}) do
    raise Rewrite.Error,
      source: rewrite,
      details: "unsupported function call",
      problems: [
        error:
          "cannot call remote function" <>
            " `#{inspect(module)}.#{function}/#{length(args)}`" <>
            " in `#{inspect(rewrite.context)}` spec"
      ]
  end
end
