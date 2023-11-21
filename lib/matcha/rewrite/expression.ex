defmodule Matcha.Rewrite.Expression do
  @moduledoc """
  Rewrites expanded Elixir expressions into Erlang match specification expressions.
  """

  alias Matcha.Rewrite
  import Matcha.Rewrite.AST, only: :macros

  @spec rewrite(Macro.t(), Rewrite.t()) :: Macro.t()
  def rewrite(expression, rewrite) do
    expression
    |> rewrite_bindings(rewrite)
    |> Rewrite.rewrite_pins(rewrite)
    |> rewrite_literals(rewrite)
    |> Rewrite.Calls.rewrite(rewrite)
  end

  @spec rewrite_bindings(Macro.t(), Rewrite.t()) :: Macro.t()
  defp rewrite_bindings(ast, rewrite) do
    Macro.postwalk(ast, fn
      {ref, _, context} = var when is_named_var(var) ->
        cond do
          Macro.Env.has_var?(rewrite.env, {ref, context}) ->
            {:__matcha__, {:const, {:unquote, [], [var]}}}

          Rewrite.Bindings.bound?(rewrite, ref) ->
            case Rewrite.Bindings.get(rewrite, ref) do
              outer_var when is_named_var(outer_var) ->
                {:__matcha__, {:const, {:unquote, [], [outer_var]}}}

              bound ->
                {:__matcha__, {:bound, Rewrite.Bindings.bound_var_to_source(rewrite, bound)}}
            end

          true ->
            raise_unbound_variable_error!(rewrite, var)
        end

      other ->
        other
    end)
  end

  @spec raise_unbound_variable_error!(Rewrite.t(), Rewrite.Bindings.var_ast()) :: no_return()
  defp raise_unbound_variable_error!(rewrite = %Rewrite{}, var) when is_var(var) do
    raise Rewrite.Error,
      source: rewrite,
      details: "when binding variables",
      problems: [
        error:
          "variable `#{Macro.to_string(var)}` was not bound in the match head:" <>
            " variables can only be introduced in the heads of clauses in match specs"
      ]
  end

  @spec rewrite_literals(Macro.t(), Rewrite.t()) :: Macro.t()
  def rewrite_literals(ast, rewrite) do
    do_rewrite_literals(ast, rewrite)
  end

  # Literal two-tuples passing literals/externals without semantic AST meaning
  defp do_rewrite_literals({:__matcha__, {:const, value}}, _rewrite) do
    {:const, value}
  end

  # Literal two-tuples dereferencing bindings
  defp do_rewrite_literals({:__matcha__, {:bound, expression}}, _rewrite) do
    expression
  end

  # Other two-tuple literals should follow rules for all other tuples
  defp do_rewrite_literals({left, right}, rewrite) do
    do_rewrite_literals({:{}, nil, [left, right]}, rewrite)
  end

  # Maps should expand keys and values separately, and work with update syntax
  defp do_rewrite_literals({:%{}, _meta, map_elements} = map_ast, rewrite) do
    case map_elements do
      [{:|, _, [{:%{}, _, _map_elements}, _map_updates]}] ->
        raise_map_update_error!(rewrite, map_ast)

      pairs when is_list(pairs) ->
        Enum.map(pairs, fn {key, value} ->
          {do_rewrite_literals(key, rewrite), do_rewrite_literals(value, rewrite)}
        end)
        |> Enum.into(%{})
    end
  end

  # Tuple literals should be wrapped in a tuple to differentiate from AST
  defp do_rewrite_literals({:{}, _meta, tuple_elements}, rewrite) do
    {tuple_elements |> do_rewrite_literals(rewrite) |> List.to_tuple()}
  end

  # Ignored assignments become the actual value
  defp do_rewrite_literals({:=, _, [{:_, _, _}, value]}, rewrite) do
    do_rewrite_literals(value, rewrite)
  end

  defp do_rewrite_literals({:=, _, [value, {:_, _, _}]}, rewrite) do
    do_rewrite_literals(value, rewrite)
  end

  defp do_rewrite_literals({:=, _, [{:_, _, _}, value]}, rewrite) do
    do_rewrite_literals(value, rewrite)
  end

  # Other assignments are invalid in expressions
  defp do_rewrite_literals({:=, _, [left, right]}, rewrite) do
    raise_match_in_expression_error!(rewrite, left, right)
  end

  # Ignored variables become the 'ignore' token
  defp do_rewrite_literals({:_, _, _} = _var, _rewrite) do
    :_
  end

  # Leave other calls alone, only expanding arguments
  defp do_rewrite_literals({name, meta, arguments}, rewrite) do
    {name, meta, do_rewrite_literals(arguments, rewrite)}
  end

  defp do_rewrite_literals([head | [{:|, _meta, [left_element, right_element]}]], rewrite) do
    [
      do_rewrite_literals(head, rewrite)
      | [
          do_rewrite_literals(left_element, rewrite)
          | do_rewrite_literals(right_element, rewrite)
        ]
    ]
  end

  defp do_rewrite_literals([{:|, _meta, [left_element, right_element]}], rewrite) do
    [
      do_rewrite_literals(left_element, rewrite)
      | do_rewrite_literals(right_element, rewrite)
    ]
  end

  defp do_rewrite_literals([head | tail], rewrite) do
    [
      do_rewrite_literals(head, rewrite)
      | do_rewrite_literals(tail, rewrite)
    ]
  end

  defp do_rewrite_literals([], _rewrite) do
    []
  end

  defp do_rewrite_literals(var, _rewrite)
       when is_var(var) do
    var
  end

  defp do_rewrite_literals({name, meta, arguments} = call, rewrite) when is_call(call) do
    {name, meta, do_rewrite_literals(arguments, rewrite), rewrite}
  end

  defp do_rewrite_literals(ast, _rewrite) when is_atomic_literal(ast) do
    ast
  end

  @spec raise_match_in_expression_error!(
          Rewrite.t(),
          Rewrite.Bindings.var_ast(),
          Rewrite.Bindings.var_ast()
        ) :: no_return()
  defp raise_match_in_expression_error!(rewrite = %Rewrite{}, left, right) do
    raise Rewrite.Error,
      source: rewrite,
      details: "when binding variables",
      problems: [
        error:
          "cannot match `#{Macro.to_string(right)}` to `#{Macro.to_string(left)}`:" <>
            " cannot use the match operator in match spec bodies"
      ]
  end

  @spec raise_map_update_error!(Rewrite.t(), Macro.t()) :: no_return()
  defp raise_map_update_error!(rewrite = %Rewrite{}, map_update) do
    raise Rewrite.Error,
      source: rewrite,
      problems: [
        error:
          "cannot use map update syntax in match specs, got: `#{Macro.to_string(map_update)}`"
      ]
  end
end
