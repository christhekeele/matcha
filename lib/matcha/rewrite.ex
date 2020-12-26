defmodule Matcha.Rewrite do
  alias Matcha.Rewrite

  @moduledoc """
  Information about rewrites.
  """

  alias Matcha.Context
  alias Matcha.Source

  alias Matcha.Spec
  alias Matcha.Pattern

  @match_all :"$_"

  defstruct [:env, :type, :context, :source, bindings: %{vars: %{}, count: 0}]

  @type t :: %__MODULE__{
          env: Macro.Env.t(),
          type: Source.type(),
          context: Context.t(),
          source: Macro.t(),
          bindings: %{
            vars: %{var_ref() => var_binding()},
            count: non_neg_integer()
          }
        }

  @type var_ast :: {atom, list, atom | nil}
  @type var_ref :: atom
  @type var_binding :: atom | var_ast

  ####
  # Rewrite match problems
  ##

  @spec problems(problems) :: Matcha.Error.problems()
        when problems: [{type, description}],
             type: :error | :warning,
             description: charlist() | String.t()
  def problems(problems) do
    Enum.map(problems, &problem/1)
  end

  @spec problem({type, description}) :: Matcha.Error.problem()
        when type: :error | :warning, description: charlist() | String.t()
  def problem(problem)

  def problem({type, description}) when type in [:error, :warning] and is_list(description) do
    {type, List.to_string(description)}
  end

  def problem({type, description}) when type in [:error, :warning] and is_binary(description) do
    {type, description}
  end

  ####
  # Rewrite matchs to specs and vice-versa
  ##

  @spec default_test_target(Source.type()) :: Source.test_target()
  def default_test_target(type)
  def default_test_target(:table), do: {}
  def default_test_target(:trace), do: []

  @spec pattern_to_test_spec(Pattern.t()) :: {:ok, Spec.t()}
  def pattern_to_test_spec(%Pattern{} = pattern) do
    {:ok,
     %Spec{
       source: [{pattern.source, [], default_test_target(pattern.type)}],
       context: pattern.context,
       type: pattern.type
     }}
  end

  @spec pattern_to_test_spec!(Pattern.t()) :: Spec.t()
  def pattern_to_test_spec!(%Pattern{} = pattern) do
    case pattern_to_test_spec(pattern) do
      {:ok, spec} ->
        spec

        # {:error, problems} -> raise Pattern.Error, source: pattern, details: "converting pattern into spec", problems: [error: ] ++ problems
    end
  end

  @spec spec_to_pattern(Spec.t()) ::
          {:ok, Pattern.t()} | {:error, Matcha.Error.problems()}
  def spec_to_pattern(spec)

  def spec_to_pattern(%Spec{source: [{pattern, _, _}]} = spec) do
    {:ok, %Pattern{source: pattern, type: spec.type, context: spec.context}}
  end

  def spec_to_pattern(%Spec{source: source}) do
    {:error,
     [
       error:
         "can only convert specs into patterns when they have a single clause, found #{
           length(source)
         } in spec: `#{inspect(source)}`"
     ]}
  end

  @spec spec_to_pattern!(Spec.t()) :: Pattern.t() | no_return()
  def spec_to_pattern!(%Spec{} = spec) do
    case spec_to_pattern(spec) do
      {:ok, pattern} ->
        pattern

      {:error, problems} ->
        raise Spec.Error, source: spec, details: "rewriting into pattern", problems: problems
    end
  end

  ####
  # Match generation
  ##

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

  @spec bound?(__MODULE__.t(), var_ref()) :: boolean
  def bound?(%__MODULE__{} = rewrite, ref) do
    !!binding(rewrite, ref)
  end

  @spec binding(__MODULE__.t(), var_ref()) :: var_binding()
  def binding(%__MODULE__{} = rewrite, ref) do
    rewrite.bindings.vars[ref]
  end

  @spec outer_var?(__MODULE__.t(), var_ast) :: boolean
  def outer_var?(%__MODULE__{} = rewrite, {ref, _, context}) do
    Macro.Env.has_var?(rewrite.env, {ref, context})
  end

  @spec rewrite_bindings(__MODULE__.t(), Macro.t()) :: Macro.t()
  def rewrite_bindings(spec, ast)

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

  @spec do_rewrite_bindings(__MODULE__.t(), Macro.t()) :: Macro.t()
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

  @spec bind_toplevel_match(__MODULE__.t(), Macro.t()) :: __MODULE__.t()
  defp bind_toplevel_match(%__MODULE__{} = rewrite, ref) do
    if bound?(rewrite, ref) do
      rewrite
    else
      var = @match_all
      bindings = %{rewrite.bindings | vars: Map.put(rewrite.bindings.vars, ref, var)}
      %{rewrite | bindings: bindings}
    end
  end

  @spec bind_var(__MODULE__.t(), var_ref()) :: __MODULE__.t()
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

  @spec rebind_var(__MODULE__.t(), var_ref(), var_ref()) :: __MODULE__.t()
  defp rebind_var(%__MODULE__{} = rewrite, ref, new_ref) do
    var = Map.get(rewrite.bindings.vars, ref)
    bindings = %{rewrite.bindings | vars: Map.put(rewrite.bindings.vars, new_ref, var)}
    %{rewrite | bindings: bindings}
  end

  @spec do_rewrite_outer_assignment(__MODULE__.t(), Macro.t()) :: {Macro.t(), __MODULE__.t()}
  defp do_rewrite_outer_assignment(rewrite, {{left_ref, _, _} = left, {right_ref, _, _} = right}) do
    cond do
      outer_var?(rewrite, left) ->
        rewrite = bind_var(rewrite, right_ref, left)
        {left, rewrite}

      outer_var?(rewrite, right) ->
        rewrite = bind_var(rewrite, left_ref, right)
        {right, rewrite}
    end
  end

  @spec do_rewrite_match_assignment(__MODULE__.t(), Macro.t()) :: {Macro.t(), __MODULE__.t()}
  defp do_rewrite_match_assignment(rewrite, {{left_ref, _, _} = left, {right_ref, _, _} = right}) do
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

  @spec rewrite_match(__MODULE__.t(), Macro.t()) :: Macro.t()
  def rewrite_match(rewrite, match)

  def rewrite_match(%__MODULE__{} = rewrite, {:=, _, [match, var]}) when is_named_var(var) do
    rewrite_match(rewrite, match)
  end

  def rewrite_match(%__MODULE__{} = rewrite, {:=, _, [var, match]}) when is_named_var(var) do
    rewrite_match(rewrite, match)
  end

  def rewrite_match(%__MODULE__{} = rewrite, match) do
    do_rewrite_match(rewrite, match)
  end

  @spec do_rewrite_match(__MODULE__.t(), Macro.t()) :: Macro.t()
  defp do_rewrite_match(rewrite, match) do
    match
    |> rewrite_match_bindings(rewrite)
    |> rewrite_pins(rewrite)
    |> rewrite_match_literals(rewrite)
    |> rewrite_calls(rewrite)
  end

  @spec rewrite_match_literals(Macro.t(), __MODULE__.t()) :: Macro.t()
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

  @spec rewrite_conditions(__MODULE__.t(), Macro.t()) :: Macro.t()
  def rewrite_conditions(rewrite, conditions) do
    conditions
    |> Enum.map(&rewrite_expr(&1, rewrite))
  end

  @spec rewrite_body(__MODULE__.t(), Macro.t()) :: Macro.t()
  def rewrite_body(rewrite, ast)

  def rewrite_body(rewrite, [{:__block__, _, body}]) do
    rewrite_body(rewrite, body)
  end

  def rewrite_body(rewrite, body) do
    rewrite_expr(body, rewrite)
  end

  @spec rewrite_expr(Macro.t(), __MODULE__.t()) :: Macro.t()
  defp rewrite_expr(expr, rewrite) do
    expr
    |> rewrite_expr_bindings(rewrite)
    |> rewrite_pins(rewrite)
    |> rewrite_expr_literals(rewrite)
    |> rewrite_calls(rewrite)
  end

  @spec rewrite_pins(Macro.t(), __MODULE__.t()) :: Macro.t()
  defp rewrite_pins(ast, _rewrite) do
    Macro.prewalk(ast, fn
      {:^, _, [value]} ->
        value

      other ->
        other
    end)
  end

  @spec rewrite_match_bindings(Macro.t(), __MODULE__.t()) :: Macro.t()
  defp rewrite_match_bindings(ast, %__MODULE__{} = rewrite) do
    Macro.postwalk(ast, fn
      {ref, _, context} = var when is_named_var(var) ->
        cond do
          Macro.Env.has_var?(rewrite.env, {ref, context}) ->
            {:unquote, [], [var]}

          bound?(rewrite, ref) ->
            binding(rewrite, ref)

          true ->
            raise_unbound_variable_error!(rewrite, var)
        end

      other ->
        other
    end)
  end

  @spec rewrite_expr_bindings(Macro.t(), __MODULE__.t()) :: Macro.t()
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
            raise_unbound_variable_error!(rewrite, var)
        end

      other ->
        other
    end)
  end

  @spec raise_unbound_variable_error!(__MODULE__.t(), var_ast()) :: no_return()
  defp raise_unbound_variable_error!(%__MODULE__{} = rewrite, var) when is_var(var) do
    raise Rewrite.Error,
      source: rewrite,
      details: "binding variables",
      problems: [error: "variable `#{Macro.to_string(var)}` was unbound"]
  end

  @spec rewrite_expr_literals(Macro.t(), __MODULE__.t()) :: Macro.t()
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

  @spec rewrite_calls(Macro.t(), __MODULE__.t()) :: Macro.t()
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
  #  call rewrites we are emitting may produce invalid Elixir AST,
  #  no matter which angle we approach the nesting from.

  @spec do_rewrite_calls(Macro.t(), __MODULE__.t()) :: Macro.t()
  defp do_rewrite_calls(ast, rewrite)

  defp do_rewrite_calls(
         {{:., _, [module, function]}, _, args} = call,
         %__MODULE__{context: context} = rewrite
       )
       when is_call(call) and context != nil and module == context do
    args = do_rewrite_calls(args, rewrite)

    if {function, length(args)} in module.__info__(:functions) do
      List.to_tuple([function | args])
    else
      raise_invalid_call_error!(rewrite, {module, function, args})
    end
  end

  defp do_rewrite_calls({{:., _, [:erlang = module, function]}, _, args} = call, rewrite)
       when is_call(call) do
    args = do_rewrite_calls(args, rewrite)

    if match_spec_safe_call?(function, length(args)) do
      List.to_tuple([function | args])
    else
      raise_invalid_call_error!(rewrite, {module, function, args})
    end
  end

  defp do_rewrite_calls({one, two, three}, rewrite) do
    {
      do_rewrite_calls(one, rewrite),
      do_rewrite_calls(two, rewrite),
      do_rewrite_calls(three, rewrite)
    }
  end

  defp do_rewrite_calls(list, rewrite) when is_list(list) do
    Enum.map(list, &do_rewrite_calls(&1, rewrite))
  end

  defp do_rewrite_calls(ast, _rewrite) do
    ast
  end

  @spec raise_invalid_call_error!(__MODULE__.t(), var_ast()) :: no_return()
  defp raise_invalid_call_error!(%__MODULE__{} = rewrite, {module, function, args}) do
    raise Rewrite.Error,
      source: rewrite,
      details: "unsupported function call",
      problems: [
        error:
          "cannot call function in #{rewrite.type} spec: " <>
            "`#{module}.#{function}(#{args |> Enum.map(&inspect/1) |> Enum.join(", ")})`"
      ]
  end
end
