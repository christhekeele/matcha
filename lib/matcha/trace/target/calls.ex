defmodule Matcha.Trace.Calls do
  alias Matcha.Trace

  alias Matcha.Context
  alias Matcha.Helpers

  alias Matcha.Spec

  @erlang_any_function :_
  @erlang_any_arity :_

  @matcha_any_function @erlang_any_function
  @matcha_any_arity :any

  @trace_flag :call

  defstruct [
    :module,
    :function,
    :arguments
  ]

  @type t :: %__MODULE__{
          module: atom(),
          function: atom(),
          arguments: unquote(@matcha_any_arity) | 0..255 | Spec.t()
        }

  def new(module, function \\ @matcha_any_function, arguments \\ @matcha_any_arity) do
    %__MODULE__{
      module: module,
      function: function,
      arguments: arguments
    }
  end

  @compile {:inline, trace_flag: 1}
  def trace_flag(%__MODULE__{}), do: @trace_flag

  def trace_patterns(%__MODULE__{} = trace) do
    trace_module = trace.module
    trace_function = trace.function

    {trace_arities, trace_specs} =
      case trace.arguments do
        @matcha_any_arity -> {[@erlang_any_arity], []}
        arity when is_integer(arity) -> {[arity], []}
        arities when is_list(arities) -> {arities, []}
        %Spec{source: source} -> {[@erlang_any_arity], source}
      end

    for trace_arity <- trace_arities do
      {{trace_module, trace_function, trace_arity}, trace_specs, [:global]}
    end
  end

  def validate(%__MODULE__{} = calls) do
    problems =
      []
      |> trace_problems_module_exists(calls.module)
      |> trace_problems_function_exists(calls.module, calls.function)
      |> trace_problems_numeric_arities_valid(calls.arguments)
      |> trace_problems_function_with_arity_exists(calls.module, calls.function, calls.arguments)
      |> trace_problems_warn_match_spec_tracing_context(calls.arguments)
      |> trace_problems_match_spec_valid(calls.arguments)

    if length(problems) > 0 do
      {:error, problems}
    else
      {:ok, calls}
    end
  end

  def validate!(%__MODULE__{} = calls) do
    case validate(calls) do
      {:ok, ^calls} ->
        calls

      {:error, problems} ->
        raise Trace.Calls.Error,
          source: calls,
          details: "when building call trace",
          problems: problems
    end
  end

  defp trace_problems_module_exists(problems, module) do
    if Helpers.module_exists?(module) do
      problems
    else
      [
        {:error, "cannot trace a module that doesn't exist: `#{module}`"}
        | problems
      ]
    end
  end

  defp trace_problems_function_exists(problems, _module, @matcha_any_function) do
    problems
  end

  defp trace_problems_function_exists(problems, module, function) do
    if Helpers.function_exists?(module, function) do
      problems
    else
      [
        {:error, "cannot trace a function that doesn't exist: `#{module}.#{function}`"}
        | problems
      ]
    end
  end

  defp trace_problems_numeric_arities_valid(problems, arguments) do
    if (is_integer(arguments) and (arguments < 0 or arguments > 255)) or
         (is_atom(arguments) and arguments != @matcha_any_arity) do
      [
        {:error,
         "invalid arguments provided to trace: `#{inspect(arguments)}`, must be an integer within `0..255`, a `Matcha.Spec`, or `#{@matcha_any_arity}`"}
        | problems
      ]
    else
      problems
    end
  end

  defp trace_problems_function_with_arity_exists(problems, module, function, arguments)
       when is_integer(arguments) and arguments in 0..255 do
    if Helpers.function_with_arity_exists?(module, function, arguments) do
      problems
    else
      [
        {:error,
         "cannot trace a function that doesn't exist: `#{module}.#{function}/#{arguments}`"}
        | problems
      ]
    end
  end

  defp trace_problems_function_with_arity_exists(problems, _module, _function, _arguments),
    do: problems

  defp trace_problems_warn_match_spec_tracing_context(problems, arguments) do
    if is_struct(arguments, Spec) and not Context.supports_tracing?(arguments.context) do
      IO.warn(
        "#{inspect(arguments)} was not defined with a `Matcha.Context` context that supports tracing," <>
          " doing so may provide better compile-time guarantees it is valid in tracing contexts," <>
          " ex. `Matcha.spec(:trace) do...`"
      )
    else
      problems
    end
  end

  defp trace_problems_match_spec_valid(problems, arguments) do
    if is_struct(arguments, Spec) do
      case Spec.validate(arguments) do
        {:ok, _spec} -> problems
        {:error, spec_problems} -> spec_problems ++ problems
      end
    else
      problems
    end
  end

  defimpl Matcha.Trace.Target do
    def trace_flag(target), do: Matcha.Trace.Calls.trace_flag(target)
    def trace_patterns(target), do: Matcha.Trace.Calls.trace_patterns(target)
    def validate(target), do: Matcha.Trace.Calls.validate(target)
    def validate!(target), do: Matcha.Trace.Calls.validate!(target)
  end
end
