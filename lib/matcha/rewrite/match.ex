defmodule Matcha.Rewrite.Match do
  alias Matcha.Rewrite
  import Matcha.Rewrite.AST, only: :macros

  @spec rewrite(Rewrite.t(), Macro.t()) :: Macro.t()
  def rewrite(rewrite, match)

  def rewrite(rewrite = %Rewrite{}, {:=, _, [match, var]}) when is_named_var(var) do
    rewrite(rewrite, match)
  end

  def rewrite(rewrite = %Rewrite{}, {:=, _, [var, match]}) when is_named_var(var) do
    rewrite(rewrite, match)
  end

  def rewrite(rewrite = %Rewrite{}, match) do
    do_rewrite(rewrite, match)
  end

  @spec do_rewrite(Rewrite.t(), Macro.t()) :: Macro.t()
  defp do_rewrite(rewrite, match) do
    match
    |> rewrite_bindings(rewrite)
    |> Rewrite.rewrite_pins(rewrite)
    |> rewrite_literals(rewrite)
    |> Rewrite.Calls.rewrite(rewrite)
  end

  @spec rewrite_literals(Macro.t(), Rewrite.t()) :: Macro.t()
  defp rewrite_literals(ast, _rewrite) do
    ast |> do_rewrite_literals
  end

  defp do_rewrite_literals({:{}, meta, tuple_elements})
       when is_list(tuple_elements) and is_list(meta) do
    tuple_elements |> do_rewrite_literals |> List.to_tuple()
  end

  defp do_rewrite_literals({:%{}, meta, map_elements})
       when is_list(map_elements) and is_list(meta) do
    map_elements |> do_rewrite_literals |> Enum.into(%{})
  end

  defp do_rewrite_literals([head | [{:|, _meta, [left_element, right_element]}]]) do
    [
      do_rewrite_literals(head)
      | [do_rewrite_literals(left_element) | do_rewrite_literals(right_element)]
    ]
  end

  defp do_rewrite_literals([{:|, _meta, [left_element, right_element]}]) do
    [do_rewrite_literals(left_element) | do_rewrite_literals(right_element)]
  end

  defp do_rewrite_literals([head | tail]) do
    [do_rewrite_literals(head) | do_rewrite_literals(tail)]
  end

  defp do_rewrite_literals([]) do
    []
  end

  defp do_rewrite_literals({left, right}) do
    {do_rewrite_literals(left), do_rewrite_literals(right)}
  end

  defp do_rewrite_literals({:_, _, _} = ignored_var)
       when is_var(ignored_var) do
    :_
  end

  defp do_rewrite_literals(var)
       when is_var(var) do
    var
  end

  defp do_rewrite_literals({name, meta, arguments} = call) when is_call(call) do
    {name, meta, do_rewrite_literals(arguments)}
  end

  defp do_rewrite_literals(ast) when is_literal(ast) do
    ast
  end

  @spec rewrite_bindings(Macro.t(), Rewrite.t()) :: Macro.t()
  defp rewrite_bindings(ast, rewrite = %Rewrite{}) do
    Macro.postwalk(ast, fn
      {ref, _, context} = var when is_named_var(var) ->
        cond do
          Macro.Env.has_var?(rewrite.env, {ref, context}) ->
            {:unquote, [], [var]}

          Rewrite.Bindings.bound?(rewrite, ref) ->
            Rewrite.Bindings.bound_var_to_source(rewrite, Rewrite.Bindings.get(rewrite, ref))

          true ->
            raise_unbound_match_variable_error!(rewrite, var)
        end

      # {:=, _, [var, literal]} when is_named_var(var) and is_literal(literal) ->
      #   {:=, _, [var, literal]}

      # {:=, _, [literal, var]} when is_named_var(var) and is_literal(literal) ->
      #   {:=, _, [literal, var]}

      other ->
        other
    end)
  end

  @spec raise_unbound_match_variable_error!(Rewrite.t(), __MODULE__.Bindings.var_ast()) ::
          no_return()
  defp raise_unbound_match_variable_error!(rewrite = %Rewrite{}, var) when is_var(var) do
    raise Rewrite.Error,
      source: rewrite,
      details: "when binding variables",
      problems: [error: "variable `#{Macro.to_string(var)}` was unbound"]
  end
end
