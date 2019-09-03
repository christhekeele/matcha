defmodule Matcha do
  @moduledoc """
  Documentation for Matcha.
  """

  defmodule Error do
    defexception [:message]
  end

  @types [:table, :trace]

  defmacro pattern(type, pattern) when type in @types do
    do_pattern(pattern, __CALLER__, type)
  end

  defmacro spec(type, do: clauses) when type in @types do
    do_spec(clauses, __CALLER__, type)
  end

  def is_allowed_internal(name, arity) do
    :erl_internal.arith_op(name, arity) or
      :erl_internal.bif(name, arity) or
      :erl_internal.bool_op(name, arity) or
      :erl_internal.comp_op(name, arity) or
      :erl_internal.list_op(name, arity) or
      :erl_internal.send_op(name, arity)
  end

  def do_pattern(pattern, env, type) do
    pattern
    |> expand_pattern(env)
    |> translate_pattern(env, type)
    |> validate_pattern(type)
    |> Macro.escape(unquote: true)
  end

  def do_spec(clauses, env, type) do
    clauses
    |> expand_clauses(env)
    |> Enum.map(fn {:->, _, clause} -> translate_clause(clause, env, type) end)
    |> validate_spec!(type)
    |> Macro.escape(unquote: true)
  end

  def expand_pattern(pattern, env) do
    {result, _scope} = :elixir_expand.expand(pattern, %{env | context: :match})
    result
  end

  def expand_clauses(clauses, env) do
    {{:fn, _, result}, _scope} = :elixir_expand.expand({:fn, [], clauses}, env)
    result
  end

  def validate_pattern(pattern, type) do
    pattern
    |> pattern_to_spec
    |> validate_spec(type)
    |> case do
      {:ok, _spec} -> pattern
      {:error, errors} -> {:error, errors}
    end
  end

  def validate_pattern!(pattern, type) do
    case validate_pattern(pattern, type) do
      {:ok, pattern} -> pattern
      {:error, errors} -> raise Error, message: Enum.join(Keyword.values(errors), "\n")
    end
  end

  def validate_spec(spec, type) do
    test =
      case type do
        :table -> {}
        :trace -> []
      end

    case :erlang.match_spec_test(test, spec, type) do
      {:ok, _, _, _} ->
        {:ok, spec}

      {:error, errors} ->
        {:error,
         Enum.map(errors, fn {:error, list} ->
           {:error, List.to_string(list)}
         end)}
    end
  end

  def validate_spec!(spec, type) do
    case validate_spec(spec, type) do
      {:ok, spec} -> spec
      {:error, errors} -> raise Error, message: Enum.join(Keyword.values(errors), "\n")
    end
  end

  def pattern_to_spec(pattern), do: [{pattern, [], '$_'}]

  ####
  # The rest of this logic is mostly stolen from
  #  https://github.com/ericmj/ex2ms
  ##

  defmacrop is_literal(term) do
    quote do
      is_atom(unquote(term)) or is_number(unquote(term)) or is_binary(unquote(term))
    end
  end

  def translate_pattern(pattern, env, type) do
    {head, _conds, _state} = translate_head(pattern, env, type)

    case head do
      %{} ->
        raise_parameter_error(head)

      _ ->
        head
    end
  end

  def translate_clause([head, body], env, type) do
    {head, conds, state} = translate_head(head, env, type)

    case head do
      %{} ->
        raise_parameter_error(head)

      _ ->
        body = translate_body(body, state)
        {head, conds, body}
    end
  end

  def translate_body({:__block__, _, exprs}, state) when is_list(exprs) do
    Enum.map(exprs, &translate_cond(&1, state))
  end

  def translate_body(expr, state) do
    [translate_cond(expr, state)]
  end

  def translate_cond({var, _, nil}, state) when is_atom(var) do
    if match_var = state.vars[var] do
      :"#{match_var}"
    else
      raise ArgumentError, message: "variable `#{var}` is unbound in matchspec"
    end
  end

  def translate_cond({left, right}, state), do: translate_cond({:{}, [], [left, right]}, state)

  # Differs from ex2ms: function calls are already expanded,
  #  into fully-module-qualified remote calls,
  #  we just want to check if they are in the :erlang or
  #  table/trace placeholder modules.
  # If they still aren't valid in matchspecs, they will be caught during
  #  the compile-time validation phase.
  def translate_cond({{:., _, [module, fun]}, _, args} = remote_call, %{type: type} = state)
      when module == :erlang or module == type do
    cond do
      :erlang.function_exported(module, fun, length(args)) ->
        :ok

      # Short-circuit expressions do get expanded into the :erlang module,
      # but don't appear in :erlang.function_exported
      module == :erlang and fun in [:andalso, :orelse] ->
        :ok

      true ->
        raise_expression_error(remote_call)
    end

    match_args = Enum.map(args, &translate_cond(&1, state))
    [fun | match_args] |> List.to_tuple()
  end

  def translate_cond({:{}, _, list}, state) when is_list(list) do
    {list |> Enum.map(&translate_cond(&1, state)) |> List.to_tuple()}
  end

  def translate_cond({:^, _, [var]}, _state) do
    {:const, {:unquote, [], [var]}}
  end

  # No longer needed--fun calls are fully expanded to module refs,
  # and handled earlier in the AST walk.

  # def translate_cond(fun_call = {fun, _, args}, state) when is_atom(fun) and is_list(args) do
  #   IO.inspect(fun_call, label: :fun_call)

  #   cond do
  #     is_allowed_internal(fun, length(args)) ->
  #       match_args = Enum.map(args, &translate_cond(&1, state))
  #       [fun | match_args] |> List.to_tuple()

  #     expansion = is_expandable(fun_call, state.env) ->
  #       translate_cond(expansion, state)

  #     # is_action_function(fun) ->
  #     #   match_args = Enum.map(args, &translate_cond(&1, state))
  #     #   [fun | match_args] |> List.to_tuple()

  #     true ->
  #       raise_expression_error(fun_call)
  #   end
  # end

  def translate_cond(list, state) when is_list(list) do
    Enum.map(list, &translate_cond(&1, state))
  end

  def translate_cond(literal, _state) when is_literal(literal) do
    literal
  end

  def translate_cond(expr, _state), do: raise_expression_error(expr)

  def translate_head([{:when, _, [param, cond]}], env, type) do
    {head, state} = translate_param(param, env, type)
    cond = translate_cond(cond, state)
    {head, [cond], state}
  end

  def translate_head([param], env, type) do
    {head, state} = translate_param(param, env, type)
    {head, [], state}
  end

  def translate_head(expr, _env, _type), do: raise_parameter_error(expr)

  def translate_param(param, env, type) do
    param = Macro.expand(param, %{env | context: :match})

    {param, state} =
      case param do
        {:=, _, [{var, _, nil}, param]} when is_atom(var) ->
          state = %{vars: [{var, "$_"}], count: 0, outer_vars: env.vars, env: env, type: type}
          {Macro.expand(param, %{env | context: :match}), state}

        {:=, _, [param, {var, _, nil}]} when is_atom(var) ->
          state = %{vars: [{var, "$_"}], count: 0, outer_vars: env.vars, env: env, type: type}
          {Macro.expand(param, %{env | context: :match}), state}

        {var, _, nil} when is_atom(var) ->
          {param, %{vars: [], count: 0, outer_vars: env.vars, env: env, type: type}}

        {:{}, _, list} when is_list(list) ->
          {param, %{vars: [], count: 0, outer_vars: env.vars, env: env, type: type}}

        {:%{}, _, list} when is_list(list) ->
          {param, %{vars: [], count: 0, outer_vars: env.vars, env: env, type: type}}

        {_, _} ->
          {param, %{vars: [], count: 0, outer_vars: env.vars, env: env, type: type}}

        _ ->
          raise_parameter_error(param)
      end

    do_translate_param(param, state)
  end

  def do_translate_param({:_, _, nil}, state) do
    {:_, state}
  end

  def do_translate_param({var, _, nil}, state) when is_atom(var) do
    if match_var = state.vars[var] do
      {:"#{match_var}", state}
    else
      match_var = "$#{state.count + 1}"

      state =
        state
        |> Map.update!(:vars, &[{var, match_var} | &1])
        |> Map.update!(:count, &(&1 + 1))

      {:"#{match_var}", state}
    end
  end

  def do_translate_param({left, right}, state) do
    do_translate_param({:{}, [], [left, right]}, state)
  end

  def do_translate_param({:{}, _, list}, state) when is_list(list) do
    {list, state} = Enum.map_reduce(list, state, &do_translate_param(&1, &2))
    {List.to_tuple(list), state}
  end

  def do_translate_param({:^, _, [var]}, state) do
    {{:unquote, [], [var]}, state}
  end

  def do_translate_param(list, state) when is_list(list) do
    Enum.map_reduce(list, state, &do_translate_param(&1, &2))
  end

  def do_translate_param(literal, state) when is_literal(literal) do
    {literal, state}
  end

  def do_translate_param({:%{}, _, list}, state) do
    Enum.reduce(list, {%{}, state}, fn {key, value}, {map, state} ->
      {key, key_state} = do_translate_param(key, state)
      {value, value_state} = do_translate_param(value, key_state)
      {Map.put(map, key, value), value_state}
    end)
  end

  def do_translate_param(expr, _state), do: raise_parameter_error(expr)

  def is_expandable(ast, env) do
    expansion = Macro.expand_once(ast, env)
    if ast !== expansion, do: expansion, else: false
  end

  def raise_expression_error(expr) do
    message = "illegal expression in matchspec:\n#{Macro.to_string(expr)}"
    raise ArgumentError, message: message
  end

  def raise_parameter_error(expr) do
    message =
      "illegal parameter to matchspec (has to be a single variable or tuple):\n" <>
        Macro.to_string(expr)

    raise ArgumentError, message: message
  end

  # ast = quote do: Matcha.pattern {:foo, _bar, baz}
  # {:matchpattern, [],
  #  [{:{}, [], [:foo, {:_bar, [], Elixir}, {:baz, [], Elixir}]}]}

  # ast =
  #   quote do
  #     Matcha.spec do
  #       {:foo, bar} when is_integer(bar) and bar > 2 -> :foo
  #       {:fizz, buzz} when is_binary(buzz) and buzz == "ASDF" -> :fizz
  #     end
  #   end

  # {:matchspec, [], [
  #   [
  #     do: [
  #       {:->, [],
  #         [
  #           [
  #             {:when, [],
  #             [
  #               {:foo, {:bar, [], Elixir}},
  #               {:and, [context: Elixir, import: Kernel],
  #                 [
  #                   {:is_integer, [context: Elixir, import: Kernel],
  #                   [{:bar, [], Elixir}]},
  #                   {:>, [context: Elixir, import: Kernel],
  #                   [{:bar, [], Elixir}, 2]}
  #                 ]}
  #             ]}
  #           ],
  #           :foo
  #         ]},
  #       {:->, [],
  #         [
  #           [
  #             {:when, [],
  #             [
  #               {:fizz, {:buzz, [], Elixir}},
  #               {:and, [context: Elixir, import: Kernel],
  #                 [
  #                   {:is_binary, [context: Elixir, import: Kernel],
  #                   [{:buzz, [], Elixir}]},
  #                   {:==, [context: Elixir, import: Kernel],
  #                   [{:buzz, [], Elixir}, "ASDF"]}
  #                 ]}
  #             ]}
  #           ],
  #           :fizz
  #         ]}
  #     ]
  #   ]
  # ]}
end
