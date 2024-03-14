defmodule Matcha.Trace.Calls do
  @moduledoc """
  About tracing calls.
  """
  alias Matcha.Context

  alias Matcha.Spec
  alias Matcha.Trace

  require Matcha

  defstruct [:module, :function, :arguments]

  @erlang_any_module :_
  @erlang_any_function :_
  @erlang_any_arity :_

  @matcha_any_module :_
  @matcha_any_function :_
  @matcha_any_arity :_

  @raw_trace_spec Matcha.Spec.raw(
                    Matcha.spec :trace do
                      _ -> return_trace()
                    end
                  )

  @type t :: %__MODULE__{
          module: module() | unquote(@matcha_any_module),
          function: atom() | unquote(@matcha_any_function),
          arguments: non_neg_integer() | Spec.t() | unquote(@matcha_any_arity)
        }

  def new(module) do
    new(module, [])
  end

  def new(module, options) when is_list(options) do
    new(module, @matcha_any_function, options)
  end

  def new(module, function) do
    new(module, function, [])
  end

  def new(module, function, options) when is_list(options) do
    new(module, function, @matcha_any_arity, options)
  end

  def new(module, function, arguments) do
    new(module, function, arguments, [])
  end

  @doc """
  Builds a new call trace.
  """
  def new(module, function, arguments, opts) do
    build!({module, function, arguments}, opts)
  end

  def options(options \\ []) do
    {[], options}
  end

  defp build!({module, function, arguments}, options) do
    {options, extra_options} = options(options)

    problems =
      if extra_options != [] do
        for option <- options do
          {:error,
           "unexpected option `#{inspect(option)}` provided to `#{inspect(__MODULE__)}.start_link/1`"}
        end
      else
        []
      end

    problems =
      problems
      # |> trace_problems_module_exists(module)
      # |> trace_problems_function_exists(module, function)
      |> trace_problems_numeric_arities_valid(arguments)
      # |> trace_problems_function_with_arity_exists(module, function, arguments)
      |> trace_problems_warn_match_spec_tracing_context(arguments)
      |> trace_problems_match_spec_valid(arguments)

    calls = %__MODULE__{
      module: module,
      function: function,
      arguments: arguments
    }

    if length(problems) > 0 do
      raise Trace.Calls.Error,
        source: calls,
        details: "when building specification",
        problems: problems
    else
      calls
    end
  end

  # defp trace_problems_module_exists(problems, @matcha_any_module) do
  #   problems
  # end

  # defp trace_problems_module_exists(problems, module) do
  #   if Helpers.module_exists?(module) do
  #     problems
  #   else
  #     [
  #       {:error, "cannot trace a module that doesn't exist: `#{inspect(module)}`"}
  #       | problems
  #     ]
  #   end
  # end

  # defp trace_problems_function_exists(problems, _module, @matcha_any_function) do
  #   problems
  # end

  # defp trace_problems_function_exists(problems, module, function) do
  #   if Helpers.function_exists?(module, function) do
  #     problems
  #   else
  #     [
  #       {:error, "cannot trace a function that doesn't exist: `#{inspect module}.#{function}`"}
  #       | problems
  #     ]
  #   end
  # end

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

  # defp trace_problems_function_with_arity_exists(problems, module, function, arguments)
  #      when is_integer(arguments) and arguments in 0..255 do
  #   if Helpers.function_with_arity_exists?(module, function, arguments) do
  #     problems
  #   else
  #     [
  #       {:error,
  #        "cannot trace a function that doesn't exist: `#{inspect(module)}.#{function}/#{arguments}`"}
  #       | problems
  #     ]
  #   end
  # end

  # defp trace_problems_function_with_arity_exists(problems, _module, _function, _arguments),
  #   do: problems

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

  @doc """
  Starts tracing `calls` for the provided `pids`.
  """
  def start(calls = %__MODULE__{}, pids) do
    module =
      case calls.module do
        @matcha_any_module -> @erlang_any_module
        module when is_atom(module) -> module
      end

    function =
      case calls.function do
        @matcha_any_function -> @erlang_any_function
        function when is_atom(function) -> function
      end

    {arity, spec} =
      case calls.arguments do
        @matcha_any_arity -> {@erlang_any_arity, @raw_trace_spec}
        arity when is_integer(arity) -> {arity, @raw_trace_spec}
        %Matcha.Spec{raw: raw} -> {@erlang_any_arity, raw}
      end

    :erlang.trace_pattern({module, function, arity}, spec)

    for pid <- pids do
      :erlang.trace(pid, true, [:call])
    end
  end

  defimpl Matcha.Trace.Topic do
    def trace(calls = %@for{}, pids) do
      @for.start(calls, pids)
    end
  end
end
