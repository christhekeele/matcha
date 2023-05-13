defmodule Matcha.Rewrite do
  @moduledoc """
  About rewrites.
  """

  alias __MODULE__

  alias Matcha.Context
  alias Matcha.Error
  alias Matcha.Source

  alias Matcha.Pattern
  alias Matcha.Spec

  defstruct [:env, :context, :source, bindings: %{vars: %{}, count: 0}]

  @type t :: %__MODULE__{
          env: Macro.Env.t(),
          context: Context.t() | nil,
          source: Macro.t(),
          bindings: %{
            vars: %{var_ref() => var_binding()},
            count: non_neg_integer()
          }
        }

  @type var_ast :: {atom, list, atom | nil}
  @type var_ref :: atom
  @type var_binding :: atom | var_ast

  @compile {:inline, source: 1}
  @spec source(t()) :: Source.uncompiled()
  def source(%__MODULE__{source: source} = _rewrite) do
    source
  end

  # Handle change in private :elixir_expand API around v1.13
  if function_exported?(:elixir_expand, :expand, 3) do
    def perform_expansion(ast, env) do
      {ast, _ex, _env} = :elixir_expand.expand(ast, :elixir_env.env_to_ex(env), env)
      ast
    end
  else
    def perform_expansion(ast, env) do
      {ast, _env} = :elixir_expand.expand(ast, env)
      ast
    end
  end

  # Rewrite Elixir AST to Macha constructs

  def ast_to_pattern_source(%__MODULE__{} = rewrite, pattern) do
    pattern
    |> expand_pattern_ast(rewrite)
    |> rewrite_pattern_ast(rewrite)
    |> Macro.escape(unquote: true)
  end

  defp expand_pattern_ast(match, rewrite) do
    perform_expansion(match, Macro.Env.to_match(rewrite.env))
  end

  defp rewrite_pattern_ast(match, rewrite) do
    {rewrite, match} = rewrite_bindings(rewrite, match)
    rewrite_match(rewrite, match)
  end

  def ast_to_spec_source(%__MODULE__{} = rewrite, spec) do
    spec
    |> expand_spec_ast(rewrite)
    |> Enum.map(&normalize_clause_ast(&1, rewrite))
    |> Enum.map(&rewrite_clause_ast(&1, rewrite))
    |> Macro.escape(unquote: true)
  end

  defp expand_spec_ast(clauses, rewrite) do
    clauses =
      for clause <- clauses do
        handle_pre_expansion!(clause, rewrite)
      end

    elixir_ast =
      quote do
        # keep up to date with the replacements in Matcha.Rewrite.Kernel
        import Kernel,
          except: [
            and: 2,
            is_boolean: 1,
            is_exception: 1,
            is_exception: 2,
            is_struct: 1,
            is_struct: 2,
            or: 2
          ]

        # use special variants of kernel macros, that otherwise wouldn't work in match spec bodies
        import Matcha.Rewrite.Kernel, warn: false
        # make special functions for this context available unadorned during expansion
        import unquote(rewrite.context), warn: false
        # mimic a `fn` definition for purposes of expanding clauses
        unquote({:fn, [], clauses})
      end

    expansion = perform_expansion(elixir_ast, rewrite.env)

    {_, clauses} =
      Macro.prewalk(expansion, nil, fn
        {:fn, [], clauses}, nil -> {nil, clauses}
        other, clauses -> {other, clauses}
      end)

    clauses
  end

  defp handle_pre_expansion!(clause, rewrite) do
    handle_in_operator!(clause, rewrite)
  end

  defp handle_in_operator!(clause, rewrite) do
    Macro.postwalk(clause, fn
      {:in, _, [left, right]} = ast ->
        cond do
          # Expand Kernel list-generating sigil literals in guard contexts specially
          match?({:sigil_C, _, _}, right) ->
            sigil_expansion = perform_expansion(right, %{rewrite.env | context: :guard})
            {:in, [], [left, sigil_expansion]}

          match?({:sigil_c, _, _}, right) ->
            sigil_expansion = perform_expansion(right, %{rewrite.env | context: :guard})
            {:in, [], [left, sigil_expansion]}

          match?({:sigil_W, _, _}, right) ->
            sigil_expansion = perform_expansion(right, %{rewrite.env | context: :guard})
            {:in, [], [left, sigil_expansion]}

          match?({:sigil_w, _, _}, right) ->
            sigil_expansion = perform_expansion(right, %{rewrite.env | context: :guard})
            {:in, [], [left, sigil_expansion]}

          # Allow literal lists
          is_list(right) and Macro.quoted_literal?(right) ->
            ast

          # Literal range syntax
          match?({:.., _, [_left, _right | []]}, right) ->
            ast

          # Literal range with step syntax
          match?({:"..//", _, [_left, _right, _step | []]}, right) ->
            ast

          true ->
            raise ArgumentError,
              message:
                Enum.join(
                  [
                    "invalid right argument for operator \"in\"",
                    "it expects a compile-time proper list or compile-time range on the right side when used in match spec expressions",
                    "got: `#{Macro.to_string(right)}`"
                  ],
                  ", "
                )
        end

      ast ->
        ast
    end)
  end

  defp normalize_clause_ast({:->, _, [[head], body]}, _rewrite) do
    {match, conditions} = :elixir_utils.extract_guards(head)
    {match, conditions, [body]}
  end

  defp normalize_clause_ast(clause, rewrite) do
    raise Rewrite.Error,
      source: rewrite,
      details: "when binding variables",
      problems: [
        error: "match spec clauses must be of arity 1, got: `#{Macro.to_string(clause)}`"
      ]
  end

  defp rewrite_clause_ast({match, conditions, body}, rewrite) do
    {rewrite, match} = rewrite_bindings(rewrite, match)
    match = rewrite_match(rewrite, match)
    conditions = rewrite_conditions(rewrite, conditions)
    body = rewrite_body(rewrite, body)
    {match, conditions, body}
  end

  ###
  # Rewrite problems
  ##

  @spec problems(problems) :: Error.problems()
        when problems: [{type, description}],
             type: :error | :warning,
             description: charlist() | binary
  def problems(problems) do
    Enum.map(problems, &problem/1)
  end

  @spec problem({type, description}) :: Error.problem()
        when type: :error | :warning, description: charlist() | binary
  def problem(problem)

  def problem({type, description}) when type in [:error, :warning] and is_list(description) do
    {type, List.to_string(description)}
  end

  def problem({type, description}) when type in [:error, :warning] and is_binary(description) do
    {type, description}
  end

  ###
  # Rewrite matches to specs and vice-versa
  ##

  @spec pattern_to_spec(Context.t(), Pattern.t()) :: {:ok, Spec.t()} | {:error, Error.problems()}
  def pattern_to_spec(context, %Pattern{} = pattern) do
    %Spec{
      source: [{Pattern.source(pattern), [], [Source.__match_all__()]}],
      context: Context.resolve(context)
    }
    |> Spec.validate()
  end

  @spec spec_to_pattern(Spec.t()) ::
          {:ok, Pattern.t()} | {:error, Error.problems()}
  def spec_to_pattern(spec)

  def spec_to_pattern(%Spec{source: [{pattern, _, _}]}) do
    {:ok, %Pattern{source: pattern}}
  end

  def spec_to_pattern(%Spec{source: source}) do
    {:error,
     [
       error:
         "can only convert specs into patterns when they have a single clause, found #{length(source)} in spec: `#{inspect(source)}`"
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

  ###
  # Rewrite Elixir to matches
  ##

  defguard is_var(var)
           when is_tuple(var) and is_atom(elem(var, 0)) and is_list(elem(var, 1)) and
                  is_atom(elem(var, 2))

  defguard is_named_var(var)
           when is_var(var) and elem(var, 0) != :_

  defguard is_call(call)
           when (is_atom(elem(call, 0)) or is_tuple(elem(call, 0))) and is_list(elem(call, 1)) and
                  is_list(elem(call, 2))

  defguard is_invocation(invocation)
           when is_call(invocation) and elem(invocation, 0) == :. and is_list(elem(invocation, 1)) and
                  length(elem(invocation, 2)) == 2 and
                  is_atom(hd(elem(invocation, 2))) and is_atom(hd(tl(elem(invocation, 2))))

  defguard is_remote_call(call)
           when is_invocation(elem(call, 0)) and is_list(elem(call, 1)) and
                  is_list(elem(call, 2))

  defguard is_literal(ast)
           when is_atom(ast) or is_integer(ast) or is_float(ast) or is_binary(ast)

  defguard is_non_literal(ast)
           when is_list(ast) or
                  (is_tuple(ast) and tuple_size(ast) == 2) or is_call(ast) or is_var(ast)

  @spec bound?(t(), var_ref()) :: boolean
  def bound?(%__MODULE__{} = rewrite, ref) do
    !!binding(rewrite, ref)
  end

  @spec binding(t(), var_ref()) :: var_binding()
  def binding(%__MODULE__{} = rewrite, ref) do
    rewrite.bindings.vars[ref]
  end

  @spec outer_var?(t(), var_ast) :: boolean
  def outer_var?(%__MODULE__{} = rewrite, {ref, _, context}) do
    Macro.Env.has_var?(rewrite.env, {ref, context})
  end

  def outer_var?(_, _) do
    false
  end

  @spec rewrite_bindings(t(), Macro.t()) :: Macro.t()
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

  @spec do_rewrite_bindings(t(), Macro.t()) :: Macro.t()
  defp do_rewrite_bindings(%__MODULE__{} = rewrite, match) do
    {ast, rewrite} =
      Macro.prewalk(match, rewrite, fn
        {:=, _, [left, right]}, rewrite when is_named_var(left) and is_named_var(right) ->
          if outer_var?(rewrite, left) or outer_var?(rewrite, right) do
            do_rewrite_outer_assignment(rewrite, {left, right})
          else
            do_rewrite_match_assignment(rewrite, {left, right})
          end

        {:=, _, [left, right]}, rewrite ->
          raise_match_in_match_error!(rewrite, left, right)

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

  @spec raise_match_in_match_error!(t(), var_ast(), var_ast()) :: no_return()
  defp raise_match_in_match_error!(%__MODULE__{} = rewrite, left, right) do
    raise Rewrite.Error,
      source: rewrite,
      details: "when binding variables",
      problems: [
        error:
          "cannot match `#{Macro.to_string(left)}` to `#{Macro.to_string(right)}`:" <>
            " cannot use the match operator in match spec heads," <>
            " except to re-assign variables to each other"
      ]
  end

  @spec bind_toplevel_match(t(), Macro.t()) :: t()
  defp bind_toplevel_match(%__MODULE__{} = rewrite, ref) do
    if bound?(rewrite, ref) do
      rewrite
    else
      var = Source.__match_all__()
      bindings = %{rewrite.bindings | vars: Map.put(rewrite.bindings.vars, ref, var)}
      %{rewrite | bindings: bindings}
    end
  end

  @spec bind_var(t(), var_ref()) :: t()
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

  @spec rebind_var(t(), var_ref(), var_ref()) :: t()
  defp rebind_var(%__MODULE__{} = rewrite, ref, new_ref) do
    var = Map.get(rewrite.bindings.vars, ref)
    bindings = %{rewrite.bindings | vars: Map.put(rewrite.bindings.vars, new_ref, var)}
    %{rewrite | bindings: bindings}
  end

  @spec do_rewrite_outer_assignment(t(), Macro.t()) :: {Macro.t(), t()}
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

  @spec do_rewrite_match_assignment(t(), Macro.t()) :: {Macro.t(), t()}
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

  @spec rewrite_match(t(), Macro.t()) :: Macro.t()
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

  @spec do_rewrite_match(t(), Macro.t()) :: Macro.t()
  defp do_rewrite_match(rewrite, match) do
    match
    |> rewrite_match_bindings(rewrite)
    |> rewrite_pins(rewrite)
    |> rewrite_match_literals(rewrite)
    |> rewrite_calls(rewrite)
  end

  @spec rewrite_match_literals(Macro.t(), t()) :: Macro.t()
  defp rewrite_match_literals(ast, _rewrite) do
    ast |> do_rewrite_match_literals
  end

  defp do_rewrite_match_literals({:{}, meta, tuple_elements})
       when is_list(tuple_elements) and is_list(meta) do
    tuple_elements |> do_rewrite_match_literals |> List.to_tuple()
  end

  defp do_rewrite_match_literals({:%{}, meta, map_elements})
       when is_list(map_elements) and is_list(meta) do
    map_elements |> do_rewrite_match_literals |> Enum.into(%{})
  end

  defp do_rewrite_match_literals([head | [{:|, _meta, [left_element, right_element]}]]) do
    [
      do_rewrite_match_literals(head)
      | [do_rewrite_match_literals(left_element) | do_rewrite_match_literals(right_element)]
    ]
  end

  defp do_rewrite_match_literals([{:|, _meta, [left_element, right_element]}]) do
    [do_rewrite_match_literals(left_element) | do_rewrite_match_literals(right_element)]
  end

  defp do_rewrite_match_literals([head | tail]) do
    [do_rewrite_match_literals(head) | do_rewrite_match_literals(tail)]
  end

  defp do_rewrite_match_literals([]) do
    []
  end

  defp do_rewrite_match_literals({left, right}) do
    {do_rewrite_match_literals(left), do_rewrite_match_literals(right)}
  end

  defp do_rewrite_match_literals({:_, _, _} = ignored_var)
       when is_var(ignored_var) do
    :_
  end

  defp do_rewrite_match_literals(var)
       when is_var(var) do
    var
  end

  defp do_rewrite_match_literals({name, meta, arguments} = call) when is_call(call) do
    {name, meta, do_rewrite_match_literals(arguments)}
  end

  defp do_rewrite_match_literals(ast) when is_literal(ast) do
    ast
  end

  @spec rewrite_conditions(t(), Macro.t()) :: Macro.t()
  def rewrite_conditions(rewrite, conditions) do
    conditions
    |> Enum.map(&rewrite_expr(&1, rewrite))
  end

  @spec rewrite_body(t(), Macro.t()) :: Macro.t()
  def rewrite_body(rewrite, ast)

  def rewrite_body(rewrite, [{:__block__, _, body}]) do
    rewrite_body(rewrite, body)
  end

  def rewrite_body(rewrite, body) do
    rewrite_expr(body, rewrite)
  end

  @spec rewrite_expr(Macro.t(), t()) :: Macro.t()
  defp rewrite_expr(expr, rewrite) do
    expr
    |> rewrite_expr_bindings(rewrite)
    |> rewrite_pins(rewrite)
    |> rewrite_expr_literals(rewrite)
    |> rewrite_calls(rewrite)
  end

  @spec rewrite_pins(Macro.t(), t()) :: Macro.t()
  defp rewrite_pins(ast, _rewrite) do
    Macro.prewalk(ast, fn
      {:^, _, [value]} ->
        value

      other ->
        other
    end)
  end

  @spec rewrite_match_bindings(Macro.t(), t()) :: Macro.t()
  defp rewrite_match_bindings(ast, %__MODULE__{} = rewrite) do
    Macro.postwalk(ast, fn
      {ref, _, context} = var when is_named_var(var) ->
        cond do
          Macro.Env.has_var?(rewrite.env, {ref, context}) ->
            {:unquote, [], [var]}

          bound?(rewrite, ref) ->
            binding(rewrite, ref)

          true ->
            raise_unbound_match_variable_error!(rewrite, var)
        end

      other ->
        other
    end)
  end

  @spec raise_unbound_match_variable_error!(t(), var_ast()) :: no_return()
  defp raise_unbound_match_variable_error!(%__MODULE__{} = rewrite, var) when is_var(var) do
    raise Rewrite.Error,
      source: rewrite,
      details: "when binding variables",
      problems: [error: "variable `#{Macro.to_string(var)}` was unbound"]
  end

  @spec rewrite_expr_bindings(Macro.t(), t()) :: Macro.t()
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

  @spec raise_unbound_variable_error!(t(), var_ast()) :: no_return()
  defp raise_unbound_variable_error!(%__MODULE__{} = rewrite, var) when is_var(var) do
    raise Rewrite.Error,
      source: rewrite,
      details: "when binding variables",
      problems: [
        error:
          "variable `#{Macro.to_string(var)}` was not bound in the match head:" <>
            " variables can only be introduced in the heads of clauses in match specs"
      ]
  end

  @spec rewrite_expr_literals(Macro.t(), t()) :: Macro.t()
  defp rewrite_expr_literals(ast, rewrite) do
    do_rewrite_expr_literals(ast, rewrite)
  end

  # Literal two-tuples two-tuples manually without semantic AST meaning
  defp do_rewrite_expr_literals({:const, right}, _rewrite) do
    {:const, right}
  end

  # Two-tuple literals should be wrapped in a tuple to differentiate from AST
  defp do_rewrite_expr_literals({left, right}, rewrite) do
    {{do_rewrite_expr_literals(left, rewrite), do_rewrite_expr_literals(right, rewrite)}}
  end

  defp do_rewrite_expr_literals({:%{}, _meta, map_elements}, rewrite) do
    map_elements |> do_rewrite_expr_literals(rewrite) |> Enum.into(%{})
  end

  # Tuple literals should be wrapped in a tuple to differentiate from AST
  defp do_rewrite_expr_literals({:{}, _meta, tuple_elements}, rewrite) do
    {tuple_elements |> do_rewrite_expr_literals(rewrite) |> List.to_tuple()}
  end

  # Ignored assignments become the actual value
  defp do_rewrite_expr_literals({:=, _, [{:_, _, _}, value]}, rewrite) do
    do_rewrite_expr_literals(value, rewrite)
  end

  defp do_rewrite_expr_literals({:=, _, [value, {:_, _, _}]}, rewrite) do
    do_rewrite_expr_literals(value, rewrite)
  end

  defp do_rewrite_expr_literals({:=, _, [{:_, _, _}, value]}, rewrite) do
    do_rewrite_expr_literals(value, rewrite)
  end

  # Other assignments are invalid in expressions
  defp do_rewrite_expr_literals({:=, _, [left, right]}, rewrite) do
    raise_match_in_expression_error!(rewrite, left, right)
  end

  # Ignored variables become the 'ignore' token
  defp do_rewrite_expr_literals({:_, _, _} = _var, _rewrite) do
    :_
  end

  # Leave other calls alone, only expanding arguments
  defp do_rewrite_expr_literals({name, meta, arguments}, rewrite) do
    {name, meta, do_rewrite_expr_literals(arguments, rewrite)}
  end

  defp do_rewrite_expr_literals([head | [{:|, _meta, [left_element, right_element]}]], rewrite) do
    [
      do_rewrite_expr_literals(head, rewrite)
      | [
          do_rewrite_expr_literals(left_element, rewrite)
          | do_rewrite_expr_literals(right_element, rewrite)
        ]
    ]
  end

  defp do_rewrite_expr_literals([{:|, _meta, [left_element, right_element]}], rewrite) do
    [
      do_rewrite_expr_literals(left_element, rewrite)
      | do_rewrite_expr_literals(right_element, rewrite)
    ]
  end

  defp do_rewrite_expr_literals([head | tail], rewrite) do
    [do_rewrite_expr_literals(head, rewrite) | do_rewrite_expr_literals(tail, rewrite)]
  end

  defp do_rewrite_expr_literals([], _rewrite) do
    []
  end

  defp do_rewrite_expr_literals(var, _rewrite)
       when is_var(var) do
    var
  end

  defp do_rewrite_expr_literals({name, meta, arguments} = call, rewrite) when is_call(call) do
    {name, meta, do_rewrite_expr_literals(arguments, rewrite), rewrite}
  end

  defp do_rewrite_expr_literals(ast, _rewrite) when is_literal(ast) do
    ast
  end

  @spec raise_match_in_expression_error!(t(), var_ast(), var_ast()) :: no_return()
  defp raise_match_in_expression_error!(%__MODULE__{} = rewrite, left, right) do
    raise Rewrite.Error,
      source: rewrite,
      details: "when binding variables",
      problems: [
        error:
          "cannot match `#{Macro.to_string(left)}` to `#{Macro.to_string(right)}`:" <>
            " cannot use the match operator in match spec bodies"
      ]
  end

  @spec rewrite_calls(Macro.t(), t()) :: Macro.t()
  defp rewrite_calls(ast, rewrite) do
    do_rewrite_calls(ast, rewrite)
  end

  @spec do_rewrite_calls(Macro.t(), t()) :: Macro.t()
  defp do_rewrite_calls(ast, rewrite)

  defp do_rewrite_calls(
         {{:., _, [module, function]}, _, args} = call,
         %__MODULE__{context: context} = rewrite
       )
       when is_remote_call(call) and module == context do
    args = do_rewrite_calls(args, rewrite)

    # Permitted calls to special functions unique to specific contexts can be looked up from the spec's context module.
    if {function, length(args)} in module.__info__(:functions) do
      List.to_tuple([function | args])
    else
      raise_invalid_call_error!(rewrite, {module, function, args})
    end
  end

  defp do_rewrite_calls({{:., _, [:erlang = module, function]}, _, args} = call, rewrite)
       when is_remote_call(call) do
    args = do_rewrite_calls(args, rewrite)

    # Permitted calls to unqualified functions and operators that appear
    #  to reference the `:erlang` kernel module post expansion.
    # They are intercepted here and looked up instead from the Erlang context before becoming an instruction.
    if {function, length(args)} in Context.Erlang.__info__(:functions) do
      List.to_tuple([function | args])
    else
      raise_invalid_call_error!(rewrite, {module, function, args})
    end
  end

  defp do_rewrite_calls([head | tail] = list, rewrite) when is_list(list) do
    [do_rewrite_calls(head, rewrite) | do_rewrite_calls(tail, rewrite)]
  end

  defp do_rewrite_calls(tuple, rewrite) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> do_rewrite_calls(rewrite)
    |> List.to_tuple()
  end

  defp do_rewrite_calls(ast, _rewrite) do
    ast
  end

  @spec raise_invalid_call_error!(t(), var_ast()) :: no_return()
  defp raise_invalid_call_error!(rewrite, call)

  if Matcha.Helpers.erlang_version() < 25 do
    for {erlang_25_function, erlang_25_arity} <- [binary_part: 2, binary_part: 3, byte_size: 1] do
      defp raise_invalid_call_error!(%__MODULE__{} = rewrite, {module, function, args})
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

  defp raise_invalid_call_error!(%__MODULE__{} = rewrite, {module, function, args}) do
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
