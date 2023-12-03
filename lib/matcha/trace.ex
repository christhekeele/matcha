defmodule Matcha.Trace do
  alias Matcha.Trace

  @moduledoc """
  About tracing.
  """

  require Matcha

  alias __MODULE__

  alias Matcha.Source

  alias Matcha.Spec

  @default_trace_limit 1
  @default_trace_pids :all
  @default_handler nil

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
    :topic,
    pids: @default_trace_pids,
    limit: @default_trace_limit,
    handler: @default_handler
  ]

  @type t :: %__MODULE__{
          topic: Trace.Calls.t(),
          limit: limit(),
          pids: pid_spec(),
          handler: (tuple() -> term())
        }

  @type limit :: limit_calls() | limit_rate()
  @type limit_calls :: non_neg_integer()
  @type limit_rate :: {limit_calls(), milliseconds :: non_neg_integer()}

  @type pid_ref ::
          pid()
          | atom()
          | binary()
          | {:global, term()}
          | {:via, module(), term()}
          | {non_neg_integer(), non_neg_integer(), non_neg_integer()}
  @type pid_spec :: pid_ref() | list(pid_ref()) | :new | :existing | :all

  # TODO: cover all cases in https://github.com/ferd/recon/blob/master/src/recon_trace.erl#L513
  @type message ::
          {:trace, pid(), :receive, list(binary())}
          | {:trace, pid(), :call,
             {module :: atom, function :: atom(), arguments :: integer() | term()}}
          | {:trace, pid(), :call,
             {module :: atom, function :: atom(), arguments :: integer() | term(), binary()}}

  @spec start(Trace.t(), keyword()) :: Trace.Supervisor.on_start_child()
  @doc """
  Starts the provided `trace`.
  """
  def start(trace = %__MODULE__{}, options \\ []) do
    {tracer_options, extra_options} = Matcha.Trace.Tracer.options(options)

    if extra_options != [] do
      problems =
        for option <- options do
          {:error,
           "unexpected option `#{inspect(option)}` provided to `#{inspect(__MODULE__)}.start/2`"}
        end

      raise Trace.Error, source: trace, details: "when starting trace", problems: problems
    else
      Trace.Supervisor.start_tracer(trace, tracer_options)
    end
  end

  @spec options(keyword()) ::
          {[{:handler, any()} | {:limit, any()} | {:pids, any()}, ...], keyword()}
  def options(options) do
    {pids, options} = Keyword.pop(options, :pids, @default_trace_pids)
    {limit, options} = Keyword.pop(options, :limit, @default_trace_limit)
    {handler, options} = Keyword.pop(options, :handler, @default_handler)

    {[pids: pids, limit: limit, handler: handler], options}
  end

  @spec new(Trace.Topic.t(), keyword()) :: t()
  @doc """
  Builds a new trace.
  """
  def new(topic, options \\ []) do
    {options, extra_options} = options(options)

    problems =
      if extra_options != [] do
        for option <- extra_options do
          {:error,
           "unexpected option `#{inspect(option)}` provided to `#{inspect(__MODULE__)}.new/2`"}
        end
      else
        []
      end

    trace = struct!(__MODULE__, [{:topic, topic} | options])

    if length(problems) > 0 do
      raise Trace.Error, source: trace, details: "when building trace", problems: problems
    else
      trace
    end
  end

  @spec module(module(), keyword()) :: Trace.Supervisor.on_start_child()
  @doc """
  Trace all calls to a `module`.

  By default, only #{@default_trace_limit} calls will be traced.
  More calls can be traced by providing an integer `:limit` in the `options`.
  """
  def module(module, options \\ [])
      when is_atom(module) and is_list(options) do
    Trace.Calls.new(module, options)
    |> do_trace_calls(options)
  end

  @spec function(module(), atom(), keyword()) :: Trace.Supervisor.on_start_child()
  @doc """
  Trace all `function` calls to `module`.

  By default, only #{@default_trace_limit} calls will be traced.
  More calls can be traced by providing an integer `:limit` in the `options`.
  """
  def function(module, function, options \\ [])
      when is_atom(module) and is_atom(function) and is_list(options) do
    Trace.Calls.new(module, function, options)
    |> do_trace_calls(options)
  end

  @spec calls(module(), atom(), non_neg_integer() | Spec.t(), keyword) ::
          Trace.Supervisor.on_start_child()
  @doc """
  Trace `function` calls to `module` with specified `arguments`.

  `arguments` may be:

  - an integer arity, only tracing function calls with that number of parameters
  - a `Matcha.Spec`, only tracing function calls whose arguments match the provided patterns

  If calling with just an arity, all matching calls will print a corresponding trace message.
  If calling with a spec, additional operations can be performed, as documented in `Matcha.Context.Trace`.

  By default, only #{@default_trace_limit} calls will be traced.
  More calls can be traced by providing an integer `:limit` in the `options`.
  """
  def calls(module, function, arguments, options \\ [])
      when is_atom(module) and is_atom(function) and
             ((is_integer(arguments) and arguments >= 0) or is_struct(arguments, Spec)) and
             is_list(options) do
    Trace.Calls.new(module, function, arguments, options)
    |> do_trace_calls(options)
  end

  defp do_trace_calls(calls, options) do
    {tracer_options, options} = Matcha.Trace.Tracer.options(options)

    calls
    |> new(options)
    |> Trace.Supervisor.start_tracer(tracer_options)
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
  Formats a trace message.
  """
  def format_message(message)

  def format_message({:trace, pid, :call, {module, function, arguments}}) do
    call = format_call(module, function, arguments, pid)

    "Matcha.Trace: #{call}\n"
  end

  def format_message({:trace, pid, :call, {module, function, arguments}, message}) do
    call = format_call(module, function, arguments, pid, message)

    "Matcha.Trace:#{call}\n"
  end

  def format_message(term) do
    "Matcha.Trace: unrecognized trace message\n```\n#{inspect(term)}\n```\n"
  end

  defp format_call(module, function, arguments, pid, message \\ nil)

  defp format_call(module, function, arguments, pid, message) when is_list(arguments) do
    arity = length(arguments)
    call = call_to_string(module, function, arity)

    " traced call `#{call}`" <>
      "\n  on pid: #{inspect(pid)}" <>
      if message do
        "\n  with message: #{message}"
      else
        ""
      end <>
      "\n  with arguments:\n```\n#{inspect(arguments)}\n```"
  end

  defp format_call(module, function, arity, pid, message) when is_integer(arity) do
    call = call_to_string(module, function, arity)

    "\n  traced call `#{call}`" <>
      "\n  on pid: #{inspect(pid)}" <>
      if message do
        "\n  with message: #{message}"
      else
        ""
      end
  end

  defp call_to_string(module, function, arity) when is_integer(arity) do
    Macro.to_string(quote(do: &(unquote(module).unquote(function) / unquote(arity))))
  end

  @doc """
  Stops all tracing at once, system-wide.
  """
  def stop do
    # TODO: augment with cancelling/killing trace tracers/handlers
    :erlang.trace(:all, false, [:all])
    :erlang.trace_pattern({:_, :_, :_}, false, [:local, :meta, :call_count, :call_time])
    :erlang.trace_pattern({:_, :_, :_}, false, [])
  end
end
