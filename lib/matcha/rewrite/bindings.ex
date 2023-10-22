defmodule Matcha.Rewrite.Bindings do
  alias Matcha.Source

  import Matcha.Rewrite.AST, only: :macros

  @type var_ast :: {atom, list, atom | nil}
  @type var_ref :: atom
  @type var_binding :: non_neg_integer | var_ast

  @spec bound?(Matcha.Rewrite.t(), var_ref()) :: boolean
  def bound?(rewrite, ref) when is_struct(rewrite, Matcha.Rewrite) do
    get(rewrite, ref) != nil
  end

  @spec get(Matcha.Rewrite.t(), var_ref()) :: var_binding()
  def get(rewrite, ref) when is_struct(rewrite, Matcha.Rewrite) do
    rewrite.bindings.vars[ref]
  end

  @spec outer_var?(Matcha.Rewrite.t(), var_ast) :: boolean
  def outer_var?(rewrite, var)

  def outer_var?(rewrite, {ref, _, context}) when is_struct(rewrite, Matcha.Rewrite) do
    Macro.Env.has_var?(rewrite.env, {ref, context})
  end

  def outer_var?(rewrite, _) when is_struct(rewrite, Matcha.Rewrite) do
    false
  end

  def bound_var_to_source(0) do
    Source.__match_all__()
  end

  def bound_var_to_source(integer) when is_integer(integer) and integer > 0 do
    :"$#{integer}"
  end

  @spec rewrite(Matcha.Rewrite.t(), Macro.t()) :: Macro.t()
  def rewrite(rewrite, ast)

  def rewrite(rewrite, {:=, _, [{ref, _, _} = var, match]})
      when is_struct(rewrite, Matcha.Rewrite) and
             is_named_var(var) do
    rewrite = bind_toplevel_match(rewrite, ref)
    do_rewrite(rewrite, match)
  end

  def rewrite(rewrite, {:=, _, [match, {ref, _, _} = var]})
      when is_struct(rewrite, Matcha.Rewrite) and
             is_named_var(var) do
    rewrite = bind_toplevel_match(rewrite, ref)
    do_rewrite(rewrite, match)
  end

  def rewrite(rewrite, match) when is_struct(rewrite, Matcha.Rewrite) do
    do_rewrite(rewrite, match)
  end

  @spec do_rewrite(Matcha.Rewrite.t(), Macro.t()) :: Macro.t()
  def do_rewrite(rewrite, match) when is_struct(rewrite, Matcha.Rewrite) do
    {ast, rewrite} =
      Macro.prewalk(match, rewrite, fn
        {:=, _, [left, right]}, rewrite when is_named_var(left) and is_named_var(right) ->
          if outer_var?(rewrite, left) or
               outer_var?(rewrite, right) do
            do_rewrite_outer_assignment(rewrite, {left, right})
          else
            do_rewrite_variable_match_assignment(rewrite, {left, right})
          end

        {:=, _, [var = {ref, _, _}, expression]}, rewrite when is_named_var(var) ->
          if outer_var?(rewrite, var) do
            {var, rewrite}
          else
            rewrite = bind_var(rewrite, ref)

            do_rewrite_expression_match_assignment(
              rewrite,
              bound_var_to_source(get(rewrite, ref)),
              expression
            )
          end

        # IO.inspect(left: left, right: right)
        # {left, rewrite}

        # {:=, _, [left, right]}, rewrite when is_named_var(left) ->
        #   raise_match_in_match_error!(rewrite, left, right)

        {ref, _, _} = var, rewrite when is_named_var(var) ->
          if outer_var?(rewrite, var) do
            {var, rewrite}
          else
            {var, bind_var(rewrite, ref)}
          end

        other, rewrite ->
          {other, rewrite}
      end)

    {rewrite, ast}
  end

  # @spec raise_match_in_match_error!(t(), var_ast(), var_ast()) ::
  #         no_return()
  # def raise_match_in_match_error!(rewrite, left, right) when is_struct(rewrite, Matcha.Rewrite) do
  #   raise Rewrite.Error,
  #     source: rewrite,
  #     details: "when binding variables",
  #     problems: [
  #       error:
  #         "cannot match `#{Macro.to_string(right)}` to `#{Macro.to_string(left)}`:" <>
  #           " cannot use the match operator in match spec heads," <>
  #           " except to re-assign variables to each other"
  #     ]
  # end

  @spec bind_toplevel_match(Matcha.Rewrite.t(), Macro.t()) :: Matcha.Rewrite.t()
  def bind_toplevel_match(rewrite, ref) when is_struct(rewrite, Matcha.Rewrite) do
    if bound?(rewrite, ref) do
      rewrite
    else
      var = 0
      bindings = %{rewrite.bindings | vars: Map.put(rewrite.bindings.vars, ref, var)}
      %{rewrite | bindings: bindings}
    end
  end

  @spec bind_var(Matcha.Rewrite.t(), var_ref()) :: Matcha.Rewrite.t()
  def bind_var(rewrite, ref, value \\ nil) when is_struct(rewrite, Matcha.Rewrite) do
    if bound?(rewrite, ref) do
      rewrite
    else
      bindings =
        if value do
          %{
            rewrite.bindings
            | vars: Map.put(rewrite.bindings.vars, ref, value)
          }
        else
          count = rewrite.bindings.count + 1
          var = count

          %{
            rewrite.bindings
            | vars: Map.put(rewrite.bindings.vars, ref, var),
              count: count
          }
        end

      %{rewrite | bindings: bindings}
    end
  end

  @spec rebind_var(Matcha.Rewrite.t(), var_ref(), var_ref()) ::
          Matcha.Rewrite.t()
  def rebind_var(rewrite, ref, new_ref) when is_struct(rewrite, Matcha.Rewrite) do
    var = Map.get(rewrite.bindings.vars, ref)
    bindings = %{rewrite.bindings | vars: Map.put(rewrite.bindings.vars, new_ref, var)}
    %{rewrite | bindings: bindings}
  end

  @spec do_rewrite_outer_assignment(Matcha.Rewrite.t(), Macro.t()) ::
          {Macro.t(), Matcha.Rewrite.t()}
  def do_rewrite_outer_assignment(rewrite, {{left_ref, _, _} = left, {right_ref, _, _} = right})
      when is_struct(rewrite, Matcha.Rewrite) do
    cond do
      outer_var?(rewrite, left) ->
        rewrite = bind_var(rewrite, right_ref, left)
        {left, rewrite}

      outer_var?(rewrite, right) ->
        rewrite = bind_var(rewrite, left_ref, right)
        {right, rewrite}
    end
  end

  @spec do_rewrite_variable_match_assignment(Matcha.Rewrite.t(), Macro.t()) ::
          {Macro.t(), Matcha.Rewrite.t()}
  def do_rewrite_variable_match_assignment(
        rewrite,
        {{left_ref, _, _} = left, {right_ref, _, _} = right}
      )
      when is_struct(rewrite, Matcha.Rewrite) do
    cond do
      bound?(rewrite, left_ref) ->
        rewrite = rebind_var(rewrite, left_ref, right_ref)
        {left, rewrite}

      bound?(rewrite, right_ref) ->
        rewrite = rebind_var(rewrite, right_ref, left_ref)
        {right, rewrite}

      true ->
        rewrite = rewrite |> bind_var(left_ref) |> rebind_var(left_ref, right_ref)
        {left, rewrite}
    end
  end

  def do_rewrite_expression_match_assignment(rewrite, var, expression)
      when is_struct(rewrite, Matcha.Rewrite) do
    {rewrite, guards} =
      do_rewrite_expression_match_assignment_into_guards(rewrite, var, [], expression)

    rewrite = %{rewrite | guards: rewrite.guards ++ :lists.reverse(guards)}
    {var, rewrite}
  end

  def do_rewrite_expression_match_assignment_into_guards(rewrite, context, guards, expression)

  # def do_rewrite_expression_match_assignment_into_guards(
  #        rewrite,
  #        context,
  #        guards,
  #        var
  #      )
  #      when is_named_var(var) do
  #   do_rewrite_expression_match_assignment_into_guards(
  #     rewrite,
  #     context,
  #     guards,
  #     {:{}, [], [two, tuple]}
  #   )
  # end

  # Rewrite literal two-tuples into tuple AST to fit other tuple literals
  def do_rewrite_expression_match_assignment_into_guards(
        rewrite,
        context,
        guards,
        {two, tuple}
      )
      when is_struct(rewrite, Matcha.Rewrite) do
    do_rewrite_expression_match_assignment_into_guards(
      rewrite,
      context,
      guards,
      {:{}, [], [two, tuple]}
    )
  end

  def do_rewrite_expression_match_assignment_into_guards(
        rewrite,
        context,
        guards,
        {:{}, _meta, elements}
      )
      when is_struct(rewrite, Matcha.Rewrite) and
             is_list(elements) do
    guards = [
      {:andalso, {:is_tuple, context}, {:==, {:tuple_size, context}, length(elements)}} | guards
    ]

    for {element, index} <- Enum.with_index(elements), reduce: {rewrite, guards} do
      {rewrite, guards} ->
        do_rewrite_expression_match_assignment_into_guards(
          rewrite,
          {:element, index + 1, context},
          guards,
          element
        )
    end
  end

  def do_rewrite_expression_match_assignment_into_guards(
        rewrite,
        context,
        guards,
        {:%{}, _meta, pairs}
      )
      when is_struct(rewrite, Matcha.Rewrite) and
             is_list(pairs) do
    guards = [
      {:is_map, context} | guards
    ]

    for {key, value} <- pairs, reduce: {rewrite, guards} do
      {rewrite, guards} ->
        guards = [{:is_map_key, key, context} | guards]

        do_rewrite_expression_match_assignment_into_guards(
          rewrite,
          {:map_get, key, context},
          guards,
          value
        )
    end
  end

  def do_rewrite_expression_match_assignment_into_guards(
        rewrite,
        context,
        guards,
        literal
      )
      when is_struct(rewrite, Matcha.Rewrite) and
             is_literal(literal) do
    {rewrite,
     [
       {:==, context, {:const, literal}}
       | guards
     ]}
  end
end
