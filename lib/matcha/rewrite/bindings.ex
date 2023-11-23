defmodule Matcha.Rewrite.Bindings do
  @moduledoc """
  Rewrites expanded Elixir variable bindings into Erlang match specification variables.

  In cases where variable bindings are not possible in ms syntax, specifically nested bindings,
  converts nested variables into a sequence of extra guards in terms of an allowed outer binding.
  """

  import Matcha.Rewrite.AST, only: :macros

  alias Matcha.Rewrite
  alias Matcha.Source

  # TODO: we can probably re-write "outer bounds" checks
  #  simply by adding them to the rewrite bindings at start

  # TODO: we can probably make this recursive at a higher level
  #  so that we are not checking for assignment both at top-level
  #  and while expanding within destructuring/assignment

  @type var_ast :: {atom, list, atom | nil}
  @type var_ref :: atom
  @type var_binding :: non_neg_integer | var_ast

  @spec bound?(Matcha.Rewrite.t(), var_ref()) :: boolean
  def bound?((%Rewrite{} = %Rewrite{}) = rewrite, ref) do
    get(rewrite, ref) != nil
  end

  @spec get(Matcha.Rewrite.t(), var_ref()) :: var_binding()
  def get(%Rewrite{} = rewrite, ref) do
    rewrite.bindings.vars[ref]
  end

  @spec outer_var?(Matcha.Rewrite.t(), var_ast) :: boolean
  def outer_var?(rewrite, var)

  def outer_var?(%Rewrite{} = rewrite, {ref, _, context}) do
    Macro.Env.has_var?(rewrite.env, {ref, context})
  end

  def outer_var?(%Rewrite{} = _rewrite, _) do
    false
  end

  def bound_var_to_source(_rewrite, 0) do
    Source.__match_all__()
  end

  def bound_var_to_source(_rewrite, integer) when is_integer(integer) and integer > 0 do
    :"$#{integer}"
  end

  def bound_var_to_source(_rewrite, expr) do
    expr
  end

  @spec rewrite(Matcha.Rewrite.t(), Macro.t()) :: Macro.t()
  def rewrite(rewrite, ast)

  def rewrite(%Rewrite{} = rewrite, {:=, _, [{ref, _, _} = var, match]}) when is_named_var(var) do
    rewrite = bind_toplevel_match(rewrite, ref)
    do_rewrite(rewrite, match)
  end

  def rewrite(%Rewrite{} = rewrite, {:=, _, [match, {ref, _, _} = var]}) when is_named_var(var) do
    rewrite = bind_toplevel_match(rewrite, ref)
    do_rewrite(rewrite, match)
  end

  def rewrite(%Rewrite{} = rewrite, match) do
    do_rewrite(rewrite, match)
  end

  @spec do_rewrite(Matcha.Rewrite.t(), Macro.t()) :: Macro.t()
  def do_rewrite(%Rewrite{} = rewrite, match) do
    {ast, rewrite} =
      Macro.prewalk(match, rewrite, fn
        {:=, _, [left, right]}, rewrite when is_named_var(left) and is_named_var(right) ->
          if outer_var?(rewrite, left) or
               outer_var?(rewrite, right) do
            do_rewrite_outer_assignment(rewrite, {left, right})
          else
            do_rewrite_variable_match_assignment(rewrite, {left, right})
          end

        {:=, _, [{ref, _, _} = var, expression]}, rewrite when is_named_var(var) ->
          if outer_var?(rewrite, var) do
            raise_match_on_outer_var_error!(rewrite, var, expression)
          else
            rewrite = bind_var(rewrite, ref)

            do_rewrite_match_binding(
              rewrite,
              bound_var_to_source(rewrite, get(rewrite, ref)),
              expression
            )
          end

        {:=, _, [expression, {ref, _, _} = var]}, rewrite when is_named_var(var) ->
          if outer_var?(rewrite, var) do
            raise_match_on_outer_var_error!(rewrite, var, expression)
          else
            rewrite = bind_var(rewrite, ref)

            do_rewrite_match_binding(
              rewrite,
              bound_var_to_source(rewrite, get(rewrite, ref)),
              expression
            )
          end

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

  @spec raise_match_on_outer_var_error!(Rewrite.t(), var_ast(), Macro.t()) ::
          no_return()
  def raise_match_on_outer_var_error!(%Rewrite{} = rewrite, var, expression) do
    raise Rewrite.Error,
      source: rewrite,
      details: "when binding variables",
      problems: [
        error:
          "cannot match `#{Macro.to_string(var)}` to `#{Macro.to_string(expression)}`:" <>
            " `#{Macro.to_string(var)}` is already bound outside of the match spec"
      ]
  end

  @spec bind_toplevel_match(Matcha.Rewrite.t(), Macro.t()) :: Matcha.Rewrite.t()
  def bind_toplevel_match(%Rewrite{} = rewrite, ref) do
    if bound?(rewrite, ref) do
      rewrite
    else
      var = 0
      bindings = %{rewrite.bindings | vars: Map.put(rewrite.bindings.vars, ref, var)}
      %{rewrite | bindings: bindings}
    end
  end

  @spec bind_var(Matcha.Rewrite.t(), var_ref()) :: Matcha.Rewrite.t()
  def bind_var(%Rewrite{} = rewrite, ref, value \\ nil) do
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
  def rebind_var(%Rewrite{} = rewrite, ref, new_ref) do
    var = Map.get(rewrite.bindings.vars, ref)
    bindings = %{rewrite.bindings | vars: Map.put(rewrite.bindings.vars, new_ref, var)}
    %{rewrite | bindings: bindings}
  end

  @spec do_rewrite_outer_assignment(Matcha.Rewrite.t(), Macro.t()) ::
          {Macro.t(), Matcha.Rewrite.t()}
  def do_rewrite_outer_assignment(%Rewrite{} = rewrite, {{left_ref, _, _} = left, {right_ref, _, _} = right}) do
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
  def do_rewrite_variable_match_assignment(%Rewrite{} = rewrite, {{left_ref, _, _} = left, {right_ref, _, _} = right}) do
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

  def do_rewrite_match_binding(%Rewrite{} = rewrite, var, expression) do
    {rewrite, guards} =
      do_rewrite_match_binding_into_guards(rewrite, var, expression)

    rewrite = %{rewrite | guards: rewrite.guards ++ guards}
    {var, rewrite}
  end

  def do_rewrite_match_binding_into_guards(rewrite, context, guards \\ [], expression)

  # Rewrite literal two-tuples into tuple AST to fit other tuple literals
  def do_rewrite_match_binding_into_guards(%Rewrite{} = rewrite, context, guards, {two, tuple}) do
    do_rewrite_match_binding_into_guards(
      rewrite,
      context,
      guards,
      {:{}, [], [two, tuple]}
    )
  end

  def do_rewrite_match_binding_into_guards(%Rewrite{} = rewrite, context, guards, {:{}, _meta, elements})
      when is_list(elements) do
    guards = [
      {:__matcha__, {:bound, {:andalso, {:is_tuple, context}, {:==, {:tuple_size, context}, length(elements)}}}}
      | guards
    ]

    for {element, index} <- Enum.with_index(elements), reduce: {rewrite, guards} do
      {rewrite, guards} ->
        do_rewrite_match_binding_into_guards(
          rewrite,
          {:element, index + 1, context},
          guards,
          element
        )
    end
  end

  def do_rewrite_match_binding_into_guards(%Rewrite{} = rewrite, context, guards, {:%{}, _meta, pairs})
      when is_list(pairs) do
    guards = [
      {:__matcha__, {:bound, {:is_map, context}}} | guards
    ]

    for {key, value} <- pairs, reduce: {rewrite, guards} do
      {rewrite, guards} ->
        guards = [{:__matcha__, {:bound, {:is_map_key, key, context}}} | guards]

        do_rewrite_match_binding_into_guards(
          rewrite,
          {:map_get, key, context},
          guards,
          value
        )
    end
  end

  def do_rewrite_match_binding_into_guards(%Rewrite{} = rewrite, context, guards, elements) when is_list(elements) do
    guards = [
      {:__matcha__, {:bound, {:is_list, context}}} | guards
    ]

    {rewrite, _context, guards} =
      for element <- elements, reduce: {rewrite, context, guards} do
        {rewrite, context, guards} ->
          case element do
            {:|, _, [head, tail]} ->
              {rewrite, guards} =
                do_rewrite_match_binding_into_guards(
                  rewrite,
                  {:hd, context},
                  guards,
                  head
                )

              {rewrite, guards} =
                do_rewrite_match_binding_into_guards(
                  rewrite,
                  {:tl, context},
                  guards,
                  tail
                )

              {rewrite, nil, guards}

            element ->
              {rewrite, guards} =
                do_rewrite_match_binding_into_guards(
                  rewrite,
                  {:hd, context},
                  guards,
                  element
                )

              {rewrite, {:tl, context}, guards}
          end
      end

    {rewrite, guards}
  end

  def do_rewrite_match_binding_into_guards(
        %Rewrite{} = rewrite,
        context,
        guards,
        {:=, _, [{ref, _, _} = var, expression]}
      )
      when is_named_var(var) do
    rewrite = bind_var(rewrite, ref, context)

    do_rewrite_match_binding_into_guards(
      rewrite,
      bound_var_to_source(rewrite, get(rewrite, ref)),
      guards,
      expression
    )
  end

  def do_rewrite_match_binding_into_guards(
        %Rewrite{} = rewrite,
        context,
        guards,
        {:=, _, [expression, {ref, _, _} = var]}
      )
      when is_named_var(var) do
    rewrite = bind_var(rewrite, ref, context)

    do_rewrite_match_binding_into_guards(
      rewrite,
      bound_var_to_source(rewrite, get(rewrite, ref)),
      guards,
      expression
    )
  end

  def do_rewrite_match_binding_into_guards(%Rewrite{} = rewrite, context, guards, {ref, _, _} = var)
      when is_named_var(var) do
    rewrite = bind_var(rewrite, ref, context)
    {rewrite, guards}
  end

  def do_rewrite_match_binding_into_guards(%Rewrite{} = rewrite, context, guards, literal)
      when is_atomic_literal(literal) do
    {rewrite,
     [
       {:==, context, {:__matcha__, {:const, literal}}}
       | guards
     ]}
  end
end
