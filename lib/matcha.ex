defmodule Matcha do
  @readme "README.md"
  @external_resource @readme
  @moduledoc_blurb @readme
                   |> File.read!()
                   |> String.split("<!-- MODULEDOC BLURB -->")
                   |> Enum.fetch!(1)
  @moduledoc_snippet @readme
                     |> File.read!()
                     |> String.split("<!-- MODULEDOC SNIPPET -->")
                     |> Enum.fetch!(1)

  @moduledoc """
  #{@moduledoc_blurb}

  #{@moduledoc_snippet}
  """

  alias Matcha.Context

  alias Matcha.Trace

  @default_context Matcha.Context.FilterMap

  @spec pattern(Macro.t()) :: Macro.t()
  @doc """
  Builds a `Matcha.Pattern` that represents a pattern matching operation on a given input.

  For more information on match patterns, consult the `Matcha.Pattern` docs.

  ## Examples

      iex> require Matcha
      ...> pattern = Matcha.pattern({x, y, x})
      ...> Matcha.Pattern.match?(pattern, {1, 2, 3})
      false
      iex> Matcha.Pattern.match?(pattern, {1, 2, 1})
      true

  """
  defmacro pattern(pattern) do
    Matcha.Rewrite.build_pattern(__CALLER__, pattern)
  end

  @spec filter(Macro.t()) :: Macro.t()
  @doc """
  Builds a `Matcha.Filter` that represents a guarded match operation on a given input.

  For more information on match filters, consult the `Matcha.Filter` docs.

  ## Examples

      iex> require Matcha
      ...> filter = Matcha.filter({x, y, z} when x > z)
      ...> Matcha.Filter.match?(filter, {1, 2, 3})
      false
      iex> Matcha.Filter.match?(filter, {3, 2, 1})
      true

  """
  defmacro filter(filter) do
    Matcha.Rewrite.build_filter(__CALLER__, filter)
  end

  @spec spec(Context.t(), Macro.t()) :: Macro.t()
  @doc """
  Builds a `Matcha.Spec` that represents a destructuring, pattern matching, and re-structuring operation in a given `context`.

  The `context` may be #{Context.__core_context_aliases__() |> Keyword.keys() |> Enum.map_join(", ", &"`#{inspect(&1)}`")}, or a `Matcha.Context` module.
  This is detailed in the `Matcha.Context` docs.

  For more information on match specs, consult the `Matcha.Spec` docs.

  ## Examples

      iex> require Matcha
      ...> spec = Matcha.spec(:table) do
      ...>   {x, y, x}
      ...>     when x > y and y > 0
      ...>       -> x
      ...>   {x, y, y}
      ...>     when x < y and y < 0
      ...>       -> y
      ...> end
      iex> Matcha.Spec.run(spec, [
      ...>   {2, 1, 2},
      ...>   {-2, -1, -1},
      ...>   {1, 2, 3}
      ...> ])
      {:ok, [2, -1]}

  """
  defmacro spec(context, spec)

  defmacro spec(context, [do: clauses] = _spec) when is_list(clauses) do
    Enum.each(clauses, fn
      {:->, _, _} ->
        :ok

      other ->
        raise ArgumentError,
          message:
            "#{__MODULE__}.spec/2 must be provided with `->` clauses," <>
              " got: `#{Macro.to_string(other)}`"
    end)

    Matcha.Rewrite.build_spec(__CALLER__, context, clauses)
  end

  defmacro spec(_context, _spec = [do: not_a_list]) when not is_list(not_a_list) do
    raise ArgumentError,
      message:
        "#{__MODULE__}.spec/2 must be provided with `->` clauses," <>
          " got: `#{Macro.to_string(not_a_list)}`"
  end

  defmacro spec(_context, not_a_block) do
    raise ArgumentError,
      message:
        "#{__MODULE__}.spec/2 requires a block argument," <>
          " got: `#{Macro.to_string(not_a_block)}`"
  end

  @spec spec(Macro.t()) :: Macro.t()
  @doc """
  Builds a `Matcha.Spec` that represents a destructuring, pattern matching, and re-structuring operation on in-memory data.

  Identical to calling `spec/2` with a `:filter_map` context. Note that this context is mostly used to experiment with match specs,
  and you should generally prefer calling `spec/2` with either a `:table` or `:trace` context
  depending on which `Matcha` APIs you intend to use:

  - Use the `:trace` context if you intend to query data with `Matcha.Trace` functions
  - Use the `:table` context if you intend to trace code execution with the `Matcha.Table` functions

  ## Examples

      iex> require Matcha
      ...> spec = Matcha.spec do
      ...>   {x, y, x}
      ...>     when x > y and y > 0
      ...>       -> x
      ...>   {x, y, y}
      ...>     when x < y and y < 0
      ...>       -> y
      ...> end
      iex> Matcha.Spec.run(spec, [
      ...>   {2, 1, 2},
      ...>   {-2, -1, -1},
      ...>   {1, 2, 3}
      ...> ])
      {:ok, [2, -1]}

  """
  defmacro spec(spec)

  defmacro spec([do: clauses] = _spec) when is_list(clauses) do
    Matcha.Rewrite.build_spec(__CALLER__, @default_context, clauses)
  end

  defmacro spec(_spec = [do: not_a_list]) when not is_list(not_a_list) do
    raise ArgumentError,
      message:
        "#{__MODULE__}.spec/1 must be provided with `->` clauses," <>
          " got: `#{Macro.to_string(not_a_list)}`"
  end

  defmacro spec(not_a_block) do
    raise ArgumentError,
      message:
        "#{__MODULE__}.spec/1 requires a block argument," <>
          " got: `#{Macro.to_string(not_a_block)}`"
  end

  @doc """
  Traces `function` calls to `module`, executing a `spec` on matching arguments.

  Tracing is a powerful feature of the BEAM VM, allowing for near zero-cost
  monitoring of what is happening in running systems.
  The functions in `Matcha.Trace` provide utilities for accessing this functionality.

  One of the most powerful forms of tracing uses match specifications:
  rather that just print information on when a certain function signature
  with some number of arguments is invoked, they let you:

  - dissect the arguments in question with pattern-matching and guards
  - take special actions in response (documented in `Matcha.Context.Trace`)

  This macro is a shortcut for constructing a `spec` with the `:trace` context via `Matcha.spec/2`,
  and tracing the specified `module` and `function` with it via `Matcha.Trace.calls/4`.

  For more information on tracing in general, consult the `Matcha.Trace` docs.

  ## Examples

      iex> require Matcha
      ...> Matcha.trace_calls(Enum, :join, limit: 3) do
      ...>   [_enumerable] -> message("using default joiner")
      ...>   [_enumerable, ""] -> message("using default joiner (but explicitly)")
      ...>   [_enumerable, _custom] -> message("using custom joiner")
      ...> end
      ...> Enum.join(1..3)
      # Prints a trace message with "using default joiner" appended
      "123"
      iex> Enum.join(1..3, "")
      # Prints a trace message with "using default joiner (but explicitly)" appended
      "123"
      iex> Enum.join(1..3, ", ")
      # Prints a trace message with "using custom joiner" appended
      "1, 2, 3"

  """
  defmacro trace_calls(module, function, opts \\ [], spec) do
    quote do
      require Matcha.Trace

      Trace.calls(
        unquote(module),
        unquote(function),
        Trace.spec(unquote(spec)),
        unquote(opts)
      )
    end
  end
end
