defmodule Matcha.Trace do
  alias Matcha.Trace

  @moduledoc """
  About tracing.
  """

  require Matcha

  alias __MODULE__

  alias Matcha.Context
  alias Matcha.Helpers
  alias Matcha.Source

  alias Matcha.Spec

  @default_trace_limit 1
  @default_trace_pids :all
  @default_duration :indefinite
  @default_formatter nil

  @recon_any_function :_
  @recon_any_arity :_

  @matcha_any_function @recon_any_function
  @matcha_any_arity :any

  @doc """
  Builds a `Matcha.Spec` for tracing purposes.

  Shorthand for `Matcha.spec(:trace, spec)`.
  """
  defmacro spec(spec) do
    quote location: :keep do
      require Matcha

      Matcha.spec(:trace, unquote(spec))
    end
  end

  defstruct [
    :module,
    :function,
    :arguments,
    pids: @default_trace_pids,
    limit: @default_trace_limit,
    duration: @default_duration,
    formatter: nil,
    recon_opts: []
  ]

  @type t :: %__MODULE__{
          module: atom(),
          function: atom(),
          arguments: unquote(@matcha_any_arity) | 0..255 | Spec.t(),
          limit: pos_integer(),
          duration: pos_integer() | :indefinite,
          pids: pid() | list(pid()) | :new | :existing | :all,
          recon_opts: Keyword.t()
        }

  @type trace_message :: binary
  # TODO: cover all cases in https://github.com/ferd/recon/blob/master/src/recon_trace.erl#L513
  @type trace_info ::
          {:trace, pid(), :receive, list(trace_message())}
          | {:trace, pid(), :call,
             {module :: atom, function :: atom(), arguments :: integer() | term()}}
          | {:trace, pid(), :call,
             {module :: atom, function :: atom(), arguments :: integer() | term(),
              trace_message()}}

  def new(module) do
    new(module, [])
  end

  def new(module, opts) when is_list(opts) do
    new(module, @matcha_any_function, opts)
  end

  def new(module, function) do
    new(module, function, [])
  end

  def new(module, function, opts) when is_list(opts) do
    new(module, function, @matcha_any_arity, opts)
  end

  def new(module, function, arguments) do
    new(module, function, arguments, [])
  end

  @doc """
  Builds a new trace.

  A custom `:formatter` function can be provided to `opts`.
  It should be a 1-arity function that accepts a `t:trace_info/0` tuple,
  and returns a message string suitable for consumption by `:io.format()`.
  """
  def new(module, function, arguments, opts) do
    build_trace!(module, function, arguments, opts)
  end

  @doc """
  Starts the provided `trace`.
  """
  def start(trace = %__MODULE__{}) do
    do_recon_trace_calls(trace)
  end

  # Ensure only valid traces are built
  defp build_trace!(module, function, arguments, opts) do
    {pids, opts} = Keyword.pop(opts, :pids, @default_trace_pids)
    {limit, opts} = Keyword.pop(opts, :limit, @default_trace_limit)
    {duration, opts} = Keyword.pop(opts, :duration, @default_duration)
    {formatter, opts} = Keyword.pop(opts, :formatter, @default_formatter)

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
      pids: pids,
      limit: limit,
      formatter: formatter,
      recon_opts: opts
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

  @spec calls(atom, atom, non_neg_integer | Spec.t(), keyword) :: :ok
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
  def calls(module, function, arguments, opts \\ [])
      when is_atom(module) and is_atom(function) and
             ((is_integer(arguments) and arguments >= 0) or is_struct(arguments, Spec)) and
             is_list(opts) do
    do_trace(module, function, arguments, opts)
  end

  # Build trace from args/opts
  defp do_trace(module, function, arguments, opts) do
    trace = new(module, function, arguments, opts)

    do_recon_trace_calls(trace)
  end

  @doc """
  The default formatter for trace messages.
  """
  def default_formatter(trace_info)

  def default_formatter({:trace, pid, :call, {module, function, arguments}}) do
    call =
      Macro.to_string(
        {{:., [], [{:__aliases__, [alias: false], [module]}, function]}, [], arguments}
      )

    "Matcha.Trace: `#{call}` called on #{inspect(pid)}\n"
  end

  def default_formatter({:trace, pid, :call, {module, function, arguments}, message}) do
    call =
      Macro.to_string(
        {{:., [], [{:__aliases__, [alias: false], [module]}, function]}, [], arguments}
      )

    "Matcha.Trace: `#{call}` called on #{inspect(pid)}: #{message}\n"
  end

  def default_formatter(term) do
    inspect(term)
  end

  # Translate a trace to :recon_trace.calls arguments and invoke it
  defp do_recon_trace_calls(%Trace{} = trace) do
    recon_module = trace.module
    recon_function = trace.function

    recon_limit = trace.limit
    recon_formatter = trace.formatter || (&default_formatter/1)
    recon_opts = trace.recon_opts

    recon_arguments_list =
      case trace.arguments do
        @matcha_any_arity -> [@recon_any_arity]
        arity when is_integer(arity) -> [arity]
        arity when is_list(arity) -> arity
        %Spec{source: source} -> [source]
      end

    recon_pids_list =
      case trace.pids do
        atom when is_atom(atom) -> [atom]
        pid when is_pid(pid) -> [pid]
        pids when is_list(pids) -> pids
      end

    Enum.zip(recon_arguments_list, recon_pids_list)
    |> Enum.each(fn {recon_arguments, recon_pids} ->
      recon_opts = [{:pid, recon_pids} | recon_opts]

      recon_opts =
        if recon_formatter do
          [{:formatter, recon_formatter} | recon_opts]
        else
          recon_opts
        end

      if trace.duration != @default_duration do
        Process.send_after(self(), :duration_expired, trace.duration)
      end

      :recon_trace.calls({recon_module, recon_function, recon_arguments}, recon_limit, recon_opts)
    end)

    :ok
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

  # Check to see if the duration for tracing has expired
  def handle_info(:duration_expired) do
    stop()
  end

  @doc """
  Stops all tracing at once.
  """
  def stop do
    :recon_trace.clear()
  end
end
