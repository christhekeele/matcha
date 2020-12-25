defmodule Matcha.Rewrite do
  @moduledoc false

  defmodule Error do
    defexception [:message]
  end

  @match_all :"$_"

  @spec default_test_target(Matcha.type()) :: [] | {}
  def default_test_target(:table), do: {}
  def default_test_target(:trace), do: []

  @spec pattern_to_test_spec(Matcha.Pattern.t()) :: {:ok, Matcha.Spec.t()}
  def pattern_to_test_spec(%Matcha.Pattern{source: source, type: type}) do
    {:ok,
     %Matcha.Spec{
       source: [{source, [], default_test_target(type)}],
       context: source.context,
       type: source.type
     }}
  end

  @spec pattern_to_test_spec!(Matcha.Pattern.t()) :: Matcha.Spec.t()
  def pattern_to_test_spec!(%Matcha.Pattern{} = pattern) do
    case pattern_to_test_spec(pattern) do
      {:ok, spec} ->
        spec
        # {:error, reason} -> raise Error, message: reason
    end
  end

  def spec_to_pattern(%Matcha.Spec{source: [{pattern, _, _}]} = spec) do
    {:ok, %Matcha.Pattern{source: pattern, type: spec.type, context: spec.context}}
  end

  def spec_to_pattern(%Matcha.Spec{source: source}) do
    {:error,
     "can only convert specs into patterns when they have a single clause, found #{length(source)} in spec: `#{
       inspect(source)
     }`"}
  end

  def spec_to_pattern!(%Matcha.Spec{} = spec) do
    case spec_to_pattern(spec) do
      {:ok, pattern} -> pattern
      {:error, reason} -> raise Error, message: reason
    end
  end

  defstruct [:env, :type, :context, bindings: %{vars: %{}, count: 0}]

  defguardp is_var(var)
            when is_atom(elem(var, 0)) and is_list(elem(var, 1)) and is_atom(elem(var, 2))

  defguardp is_named_var(var)
            when is_var(var) and elem(var, 0) != :_

  defguardp is_invocation(invocation)
            when elem(invocation, 0) == :. and is_list(elem(invocation, 1)) and
                   length(elem(invocation, 2)) == 2 and
                   is_atom(hd(elem(invocation, 2))) and is_atom(hd(tl(elem(invocation, 2))))

  defguardp is_call(call)
            when is_invocation(elem(call, 0)) and is_list(elem(call, 1)) and
                   is_list(elem(call, 2))

  def bound?(%__MODULE__{} = rewrite, ref) do
    !!binding(rewrite, ref)
  end

  def binding(%__MODULE__{} = rewrite, ref) do
    rewrite.bindings.vars[ref]
  end

  def outer_var?(%__MODULE__{} = rewrite, {ref, _, context}) do
    Macro.Env.has_var?(rewrite.env, {ref, context})
  end

  def rewrite_bindings(%__MODULE__{} = rewrite, {:=, _, [{ref, _, _} = var, match]})
      when is_named_var(var) do
    rewrite = bind_toplevel_match(rewrite, ref)
    do_rewrite_bindings(rewrite, match)
  end

  def rewrite_bindings(%__MODULE__{} = rewrite, {:=, _, [match, {ref, _, _} = var]})
      when is_named_var(var) do
    rewrite = bind_toplevel_match(rewrite, ref)
    do_rewrite_bindings(rewrite, match)
  end

  def rewrite_bindings(%__MODULE__{} = rewrite, match) do
    do_rewrite_bindings(rewrite, match)
  end

  def do_rewrite_bindings(%__MODULE__{} = rewrite, match) do
    {ast, rewrite} =
      Macro.prewalk(match, rewrite, fn
        {:=, _, [left, right]}, rewrite when is_named_var(left) and is_named_var(right) ->
          if outer_var?(rewrite, left) or outer_var?(rewrite, right) do
            do_rewrite_outer_assignment(rewrite, {left, right})
          else
            do_rewrite_match_assignment(rewrite, {left, right})
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

  defp bind_toplevel_match(%__MODULE__{} = rewrite, ref) do
    if bound?(rewrite, ref) do
      rewrite
    else
      var = @match_all
      bindings = %{rewrite.bindings | vars: Map.put(rewrite.bindings.vars, ref, var)}
      %{rewrite | bindings: bindings}
    end
  end

  defp bind_var(%__MODULE__{} = rewrite, ref, value \\ nil) do
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
          var = :"$#{count}"

          %{
            rewrite.bindings
            | vars: Map.put(rewrite.bindings.vars, ref, var),
              count: count
          }
        end

      %{rewrite | bindings: bindings}
    end
  end

  defp rebind_var(%__MODULE__{} = rewrite, ref, new_ref) do
    var = Map.get(rewrite.bindings.vars, ref)
    bindings = %{rewrite.bindings | vars: Map.put(rewrite.bindings.vars, new_ref, var)}
    %{rewrite | bindings: bindings}
  end

  defp do_rewrite_outer_assignment(rewrite, {{left_ref, _, _} = left, {right_ref, _, _} = right}) do
    cond do
      outer_var?(rewrite, left) ->
        rewrite = bind_var(rewrite, right_ref, left)
        {left, rewrite}

      outer_var?(rewrite, right) ->
        rewrite = bind_var(rewrite, left_ref, right)
        {right, rewrite}

      true ->
        raise Error, message: "handle error later"
    end
  end

  defp do_rewrite_match_assignment(rewrite, {{left_ref, _, _} = left, {right_ref, _, _} = right}) do
    cond do
      bound?(rewrite, left_ref) and bound?(rewrite, right_ref) ->
        raise Error, message: "rewrite into guard later"

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

  def rewrite_match(%__MODULE__{} = rewrite, {:=, _, [match, var]}) when is_named_var(var) do
    rewrite_match(rewrite, match)
  end

  def rewrite_match(%__MODULE__{} = rewrite, {:=, _, [var, match]}) when is_named_var(var) do
    rewrite_match(rewrite, match)
  end

  def rewrite_match(%__MODULE__{} = rewrite, match) do
    do_rewrite_match(rewrite, match)
  end

  defp do_rewrite_match(rewrite, match) do
    match
    |> rewrite_match_bindings(rewrite)
    |> rewrite_pins(rewrite)
    |> rewrite_match_literals(rewrite)
    |> rewrite_calls(rewrite)
  end

  defp rewrite_match_literals(ast, _rewrite) do
    Macro.postwalk(ast, fn
      # Literal tuples do not need to be wrapped in matches
      {:{}, _, list} when is_list(list) ->
        list |> List.to_tuple()

      # Maps should be expanded
      {:%{}, _, list} when is_list(list) ->
        list |> Enum.into(%{})

      # Ignored variables become the 'ignore' token
      {:_, _, _} = ignore when is_var(ignore) ->
        :_

      other ->
        other
    end)
  end

  def rewrite_conditions(rewrite, conditions) do
    conditions
    |> Enum.map(&rewrite_expr(&1, rewrite))
  end

  def rewrite_body(rewrite, [{:__block__, _, body}]) do
    rewrite_body(rewrite, body)
  end

  def rewrite_body(rewrite, body) do
    rewrite_expr(body, rewrite)
  end

  defp rewrite_expr(expr, rewrite) do
    expr
    |> rewrite_expr_bindings(rewrite)
    |> rewrite_pins(rewrite)
    |> rewrite_expr_literals(rewrite)
    |> rewrite_calls(rewrite)
  end

  defp rewrite_pins(ast, _rewrite) do
    Macro.prewalk(ast, fn
      {:^, _, [value]} ->
        value

      other ->
        other
    end)
  end

  defp rewrite_match_bindings(ast, %__MODULE__{} = rewrite) do
    Macro.postwalk(ast, fn
      {ref, _, context} = var when is_named_var(var) ->
        cond do
          Macro.Env.has_var?(rewrite.env, {ref, context}) ->
            {:unquote, [], [var]}

          bound?(rewrite, ref) ->
            binding(rewrite, ref)

          true ->
            raise Error,
              message: "unbound variable in match spec: `#{ref}`"
        end

      other ->
        other
    end)
  end

  defp rewrite_expr_bindings(ast, rewrite) do
    Macro.postwalk(ast, fn
      {ref, _, context} = var when is_named_var(var) ->
        cond do
          Macro.Env.has_var?(rewrite.env, {ref, context}) ->
            {:const, {:unquote, [], [var]}}

          bound?(rewrite, ref) ->
            case binding(rewrite, ref) do
              outer_var when is_named_var(outer_var) ->
                {:const, {:unquote, [], [outer_var]}}

              bound ->
                bound
            end

          true ->
            raise Error,
              message: "unbound variable in match spec: `#{ref}`"
        end

      other ->
        other
    end)
  end

  defp rewrite_expr_literals(ast, _rewrite) do
    Macro.postwalk(ast, fn
      # Literal tuples must be wrapped in a tuple to differentiate from AST
      {:{}, _, list} when is_list(list) ->
        {list |> List.to_tuple()}

      # As must two-tuples without semantic meaning
      {:const, right} ->
        {:const, right}

      {left, right} ->
        {{left, right}}

      # Maps should be expanded
      {:%{}, _, list} when is_list(list) ->
        list |> Enum.into(%{})

      # Ignored assignments become the actual value
      {:=, _, [{:_, _, _} = ignore, value]} when is_var(ignore) ->
        value

      {:=, _, [value, {:_, _, _} = ignore]} when is_var(ignore) ->
        value

      # # Ignored variables become the 'ignore' token
      # {:_, _, _} = ignore when is_var(ignore) ->
      #   :_

      other ->
        other
    end)
  end

  defp rewrite_calls(ast, rewrite) do
    do_rewrite_calls(ast, rewrite)
  end

  defp match_spec_safe_call?(function, arity) do
    :erl_internal.arith_op(function, arity) or :erl_internal.bool_op(function, arity) or
      :erl_internal.comp_op(function, arity) or :erl_internal.guard_bif(function, arity) or
      :erl_internal.send_op(function, arity) or {:andalso, 2} == {function, arity} or
      {:orelse, 2} == {function, arity}
  end

  # Macro.prewalk/postwalk/traverse cannot help us now; the potentially nested
  #  call rewrites we are emitting may be invalid Elixir AST,
  #  no matter which angle we approach the nesting from.
  def do_rewrite_calls(
        {{:., _, [module, function]}, _, args} = call,
        %__MODULE__{context: context} = rewrite
      )
      when is_call(call) and context != nil and module == context do
    args = do_rewrite_calls(args, rewrite)

    if {function, length(args)} in module.__info__(:functions) do
      List.to_tuple([function | args])
    else
      raise Error,
        message:
          "cannot call function in #{rewrite.type} spec: " <>
            "`#{module}.#{function}(#{args |> Enum.map(&inspect/1) |> Enum.join(", ")})`"
    end
  end

  def do_rewrite_calls({{:., _, [:erlang = module, function]}, _, args} = call, rewrite)
      when is_call(call) do
    args = do_rewrite_calls(args, rewrite)

    if match_spec_safe_call?(function, length(args)) do
      List.to_tuple([function | args])
    else
      raise Error,
        message:
          "cannot call function in #{rewrite.type} spec: " <>
            "`#{module}.#{function}(#{args |> Enum.map(&inspect/1) |> Enum.join(", ")})`"
    end
  end

  def do_rewrite_calls({one, two, three}, rewrite) do
    {
      do_rewrite_calls(one, rewrite),
      do_rewrite_calls(two, rewrite),
      do_rewrite_calls(three, rewrite)
    }
  end

  def do_rewrite_calls(list, rewrite) when is_list(list) do
    Enum.map(list, &do_rewrite_calls(&1, rewrite))
  end

  def do_rewrite_calls(ast, _rewrite) do
    ast
  end
end
