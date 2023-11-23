defmodule Matcha.Rewrite do
  @moduledoc """
  The compiler used to expand and rewrite Elixir code into `Matcha` constructs.
  """

  import Rewrite.AST, only: :macros

  alias Matcha.Context
  alias Matcha.Error
  alias Matcha.Filter
  alias Matcha.Pattern
  alias Matcha.Rewrite
  alias Matcha.Source
  alias Matcha.Spec

  defstruct [:env, :context, :code, bindings: %{vars: %{}, count: 0}, guards: []]

  @type t :: %__MODULE__{
          env: Macro.Env.t(),
          context: Context.t() | nil,
          code: Macro.t(),
          bindings: %{
            vars: %{Rewrite.Bindings.var_ref() => Rewrite.Bindings.var_binding()},
            count: non_neg_integer()
          }
        }

  @spec code(t()) :: Source.uncompiled()
  def code(%Rewrite{code: code} = _rewrite) do
    code
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

  def build_pattern(%Macro.Env{} = env, pattern) do
    {source, bindings} =
      pattern(%Rewrite{env: env, code: pattern}, pattern)

    source = Macro.escape(source, unquote: true)
    bindings = Macro.escape(bindings, unquote: true)

    quote location: :keep do
      Matcha.Pattern.validate!(%Matcha.Pattern{source: unquote(source), bindings: unquote(bindings)})
    end
  end

  def pattern(%Rewrite{} = rewrite, pattern) do
    pattern = expand_pattern(rewrite, pattern)
    rewrite_pattern(rewrite, pattern)
  end

  defp expand_pattern(rewrite, pattern) do
    perform_expansion(pattern, Macro.Env.to_match(rewrite.env))
  end

  defp rewrite_pattern(rewrite, pattern) do
    {rewrite, pattern} = Rewrite.Bindings.rewrite(rewrite, pattern)
    {Rewrite.Match.rewrite(rewrite, pattern), rewrite.bindings.vars}
  end

  def build_filter(%Macro.Env{} = env, filter) do
    {source, bindings} =
      filter(%Rewrite{env: env, code: filter}, filter)

    source = Macro.escape(source, unquote: true)
    bindings = Macro.escape(bindings, unquote: true)

    quote location: :keep do
      Matcha.Filter.validate!(%Matcha.Filter{source: unquote(source), bindings: unquote(bindings)})
    end
  end

  def filter(%Rewrite{} = rewrite, filter) do
    filter = expand_filter(rewrite, filter)
    {rewrite, filter} = rewrite_filter(rewrite, filter)
    {filter, rewrite.bindings.vars}
  end

  defp expand_filter(rewrite, filter) do
    {_, bound_vars} =
      Macro.prewalk(filter, [], fn
        {_ref, _, _} = var, bound_vars when is_named_var(var) ->
          if Rewrite.Bindings.outer_var?(rewrite, var) do
            {var, bound_vars}
          else
            {var, [var | bound_vars]}
          end

        other, bound_vars ->
          {other, bound_vars}
      end)

    # Expand with a body that uses all bound vars to prevent warnings
    clause = {:->, [], [[filter], [{:{}, [], Enum.uniq(bound_vars)}]]}
    _ = handle_pre_expansion!(clause, rewrite)

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
        # mimic a `fn` definition for purposes of expanding clauses
        unquote({:fn, [], [clause]})
      end

    expansion = perform_expansion(elixir_ast, rewrite.env)

    {_, clause} =
      Macro.prewalk(expansion, nil, fn
        {:fn, [], [clause]}, nil -> {nil, clause}
        other, clause -> {other, clause}
      end)

    {:->, _, [[filter], _]} = clause
    :elixir_utils.extract_guards(filter)
  end

  defp rewrite_filter(rewrite, {match, guards}) do
    {rewrite, match} = Rewrite.Bindings.rewrite(rewrite, match)
    match = Rewrite.Match.rewrite(rewrite, match)

    guards = Rewrite.Guards.rewrite(guards, rewrite)

    {rewrite, {match, guards}}
  end

  def build_spec(%Macro.Env{} = env, context, clauses) do
    context =
      context
      |> perform_expansion(env)
      |> Context.resolve()

    {source, bindings} =
      %Rewrite{env: env, context: context, code: clauses}
      |> spec(clauses)
      |> Enum.with_index()
      |> Enum.reduce({[], %{}}, fn {{clause, bindings}, index}, {source, all_bindings} ->
        {[clause | source], Map.put(all_bindings, index, bindings)}
      end)

    source = Macro.escape(:lists.reverse(source), unquote: true)
    bindings = Macro.escape(bindings)

    quote location: :keep do
      Matcha.Spec.validate!(%Matcha.Spec{source: unquote(source), context: unquote(context), bindings: unquote(bindings)})
    end
  end

  def spec(%Rewrite{} = rewrite, spec) do
    rewrite
    |> expand_spec_clauses(spec)
    |> Enum.map(&Rewrite.Clause.new(&1, rewrite))
    |> Enum.map(&Rewrite.Clause.rewrite(&1, rewrite))
  end

  defp expand_spec_clauses(rewrite, clauses) do
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
  # Rewrite matches and filters to specs
  ##

  @spec pattern_to_spec(Context.t(), Pattern.t()) :: {:ok, Spec.t()} | {:error, Error.problems()}
  def pattern_to_spec(context, %Pattern{} = pattern) do
    Spec.validate(%Spec{
      source: [{Pattern.raw(pattern), [], [Source.__match_all__()]}],
      context: Context.resolve(context),
      bindings: %{0 => pattern.bindings}
    })
  end

  @spec pattern_to_matched_variables_spec(Context.t(), Pattern.t()) ::
          {:ok, Spec.t()} | {:error, Error.problems()}
  def pattern_to_matched_variables_spec(context, %Pattern{} = pattern) do
    Spec.validate(%Spec{
      source: [{Pattern.raw(pattern), [], [Source.__all_matches__()]}],
      context: Context.resolve(context),
      bindings: %{0 => pattern.bindings}
    })
  end

  @spec filter_to_spec(Context.t(), Filter.t()) :: {:ok, Spec.t()} | {:error, Error.problems()}
  def filter_to_spec(context, %Filter{} = filter) do
    {match, conditions} = Filter.raw(filter)

    Spec.validate(%Spec{
      source: [{match, conditions, [Source.__match_all__()]}],
      context: Context.resolve(context),
      bindings: %{0 => filter.bindings}
    })
  end

  @spec filter_to_matched_variables_spec(Context.t(), Filter.t()) ::
          {:ok, Spec.t()} | {:error, Error.problems()}
  def filter_to_matched_variables_spec(context, %Filter{} = filter) do
    {match, conditions} = Filter.raw(filter)

    Spec.validate(%Spec{
      source: [{match, conditions, [Source.__all_matches__()]}],
      context: Context.resolve(context),
      bindings: %{0 => filter.bindings}
    })
  end

  @spec rewrite_pins(Macro.t(), t()) :: Macro.t()
  def rewrite_pins(ast, _rewrite) do
    do_rewrite_pins(ast)
  end

  def do_rewrite_pins({:^, _, [value]}) do
    value
  end

  def do_rewrite_pins({left, right}) do
    {do_rewrite_pins(left), do_rewrite_pins(right)}
  end

  def do_rewrite_pins({call, meta, args}) do
    {do_rewrite_pins(call), meta, do_rewrite_pins(args)}
  end

  def do_rewrite_pins(args) when is_list(args) do
    for arg <- args do
      do_rewrite_pins(arg)
    end
  end

  def do_rewrite_pins(other) do
    other
  end
end
