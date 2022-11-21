defmodule Matcha.Trace do
  alias Matcha.Trace

  @moduledoc """
  About tracing.
  """

  require Matcha

  alias Matcha.Context
  alias Matcha.Helpers
  alias Matcha.Source

  alias Matcha.Spec

  @default_trace_limit 1
  @recon_any_function :_
  @matcha_any_function @recon_any_function
  @recon_any_arity :_
  @matcha_any_arity :any

  defstruct [:module, :function, :arguments, limit: @default_trace_limit, opts: []]

  @type t :: %__MODULE__{
          module: atom(),
          function: atom(),
          arguments: unquote(@matcha_any_arity) | 0..255 | Spec.t(),
          limit: pos_integer(),
          opts: Keyword.t()
        }

  # Ensure only valid traces are built
  defp build_trace!(module, function, arguments, limit, opts) do
    problems =
      []
      |> trace_problems_module_exists(module)
      |> trace_problems_function_exists(module, function)
      |> trace_problems_numeric_arities_valid(arguments)
      |> trace_problems_function_with_arity_exists(module, function, arguments)
      |> trace_problems_warn_match_spec_tracing_context(arguments)
      |> trace_problems_match_spec_valid(arguments)

    trace = %__MODULE__{
      module: module,
      function: function,
      arguments: arguments,
      limit: limit,
      opts: opts
    }

    if length(problems) > 0 do
      raise Trace.Error, source: trace, details: "when building trace", problems: problems
    else
      trace
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

  # TODO: use is_struct(arguments, Spec) once we drop support for elixir v1.10.0
  defp trace_problems_warn_match_spec_tracing_context(problems, arguments) do
    if is_map(arguments) and Map.get(arguments, :__struct__) == Spec and
         not Context.supports_tracing?(arguments.context) do
      IO.warn(
        "#{inspect(arguments)} was not defined with a `Matcha.Context` context that supports tracing," <>
          " doing so may provide better compile-time guarantees it is valid in tracing contexts," <>
          " ex. `Matcha.spec(:trace) do...`"
      )
    else
      problems
    end
  end

  # TODO: use is_struct(arguments, Spec) once we drop support for elixir v1.10.0
  defp trace_problems_match_spec_valid(problems, arguments) do
    if is_map(arguments) and Map.get(arguments, :__struct__) == Spec do
      case Spec.validate(arguments) do
        {:ok, _spec} -> problems
        {:error, spec_problems} -> spec_problems ++ problems
      end
    else
      problems
    end
  end

  @spec calls(atom, atom, non_neg_integer | Spec.t(), keyword) :: t
  @doc """
  Trace `function` calls to `module` with specified `arguments`.

  `arguments` may be:

  - an integer arity, only tracing function calls with that number of parameters
  - a `Matcha.Spec`, only tracing function calls whose arguments match the provided patterns

  If calling with just an arity, all matching calls will print a corresponding trace message.
  If calling with a spec, additional operations can be performed, as documented in `Matcha.Context.Trace`.

  By default, only #{@default_trace_limit} calls will be traced.
  More calls can be traced by providing an integer `:limit` in the `opts`.

  All other `opts` are forwarded to
  [`:recon_trace.calls/3`](https://ferd.github.io/recon/recon_trace.html#calls-3)
  as the third argument.
  """
  # TODO: use or is_struct(arguments, Spec) when we drop support for v1.10.x
  def calls(module, function, arguments, opts \\ [])
      when is_atom(module) and is_atom(function) and
             ((is_integer(arguments) and arguments >= 0) or is_struct(arguments)) and
             is_list(opts) do
    do_trace(module, function, arguments, opts)
  end

  @doc """
  Trace all `function` calls to `module`.

  By default, only #{@default_trace_limit} calls will be traced.
  More calls can be traced by providing an integer `:limit` in the `opts`.

  All other `opts` are forwarded to
  [`:recon_trace.calls/3`](https://ferd.github.io/recon/recon_trace.html#calls-3)
  as the third argument.
  """
  def function(module, function, opts \\ [])
      when is_atom(module) and is_atom(function) and is_list(opts) do
    do_trace(module, function, @matcha_any_arity, opts)
  end

  @doc """
  Trace all calls to a `module`.

  By default, only #{@default_trace_limit} calls will be traced.
  More calls can be traced by providing an integer `:limit` in the `opts`.

  All other `opts` are forwarded to
  [`:recon_trace.calls/3`](https://ferd.github.io/recon/recon_trace.html#calls-3)
  as the third argument.
  """
  def module(module, opts \\ [])
      when is_atom(module) and is_list(opts) do
    do_trace(module, @matcha_any_function, @matcha_any_arity, opts)
  end

  # Build trace from args/opts
  defp do_trace(module, function, arguments, opts) do
    {limit, opts} = Keyword.pop(opts, :limit, @default_trace_limit)
    trace = build_trace!(module, function, arguments, limit, opts)

    do_recon_trace_calls(trace)

    trace
  end

  # Translate a trace to :recon_trace.calls arguments and invoke it
  defp do_recon_trace_calls(%Trace{} = trace) do
    recon_module = trace.module

    recon_function =
      case trace.function do
        @matcha_any_function -> @recon_any_function
        function -> function
      end

    recon_arguments =
      case trace.arguments do
        @matcha_any_arity -> @recon_any_arity
        arity when is_integer(arity) -> arity
        %Spec{source: source} -> source
      end

    recon_limit = trace.limit

    recon_opts = trace.opts

    :recon_trace.calls({recon_module, recon_function, recon_arguments}, recon_limit, recon_opts)
  end

  @spec awaiting_messages?(:all | pid, timeout :: non_neg_integer()) :: boolean
  @doc """
  Checks if `pid` is awaiting trace messages.

  Waits `timeout` milliseconds for the `pid` to report that all trace messages
  intended for it when `awaiting_messages?/2` was called have been delivered.

  Returns `true` if no response is received within `timeout`, and you may assume
  that `pid` is still working through trace messages it has received.
  If it receives confirmation before the `timeout`, returns `false`.

  The `pid` must refer to an alive (or previously alive) process
  ***from the same node this function is called from***,
  or it will raise an `ArgumentError`.

  If the atom `:all` is provided instead of a `pid`, this function returns `true`
  if ***any*** process on the current node is awaiting trace messages.

  This function is best used when shutting down processes (or the current node),
  to give them a chance to finish any tracing they are handling.

  """
  def awaiting_messages?(pid \\ :all, timeout \\ 5000) do
    ref = request_confirmation_all_messages_delivered(pid)

    receive do
      {:trace_delivered, ^pid, ^ref} -> false
    after
      timeout -> true
    end
  end

  defp request_confirmation_all_messages_delivered(pid) do
    :erlang.trace_delivered(pid)
  end

  @type info_subject ::
          pid
          | port
          | :new
          | :new_processes
          | :new_ports
          | {module, function :: atom, arity :: non_neg_integer}
          | :on_load
          | :send
          | :receive

  @type info_item ::
          :flags
          | :tracer
          | :traced
          | :match_spec
          | :meta
          | :meta_match_spec
          | :call_count
          | :call_time
          | :all

  @type info_result ::
          :undefined
          | {:flags, [info_flag]}
          | {:tracer, pid | port | []}
          | {:tracer, module, any}
          | info_item_result
          | {:all, [info_item_result] | false | :undefined}

  @type info_flag ::
          :send
          | :receive
          | :set_on_spawn
          | :call
          | :return_to
          | :procs
          | :set_on_first_spawn
          | :set_on_link
          | :running
          | :garbage_collection
          | :timestamp
          | :monotonic_timestamp
          | :strict_monotonic_timestamp
          | :arity

  @type info_item_result ::
          {:traced, :global | :local | false | :undefined}
          | {:match_spec, Source.uncompiled() | false | :undefined}
          | {:meta, pid | port | false | :undefined | []}
          | {:meta, module, any}
          | {:meta_match_spec, Source.uncompiled() | false | :undefined}
          | {:call_count, non_neg_integer | boolean | :undefined}
          | {:call_time,
             [{pid, non_neg_integer, non_neg_integer, non_neg_integer}]
             | boolean
             | :undefined}

  @spec info(info_subject, info_item) :: info_result
  def info(pid_port_func_event, item) do
    :erlang.trace_info(pid_port_func_event, item)
  end

  @doc """
  Stops all tracing at once.
  """
  def stop do
    :recon_trace.clear()
  end
end
