defmodule Matcha.Trace do
  alias Matcha.Trace

  @moduledoc """
  About tracing.
  """

  require Matcha

  alias __MODULE__

  alias Matcha.Source

  alias Matcha.Spec

  @erlang_all_pids :all
  @matcha_all_pids @erlang_all_pids

  @default_trace_limit 1
  @default_trace_pids @matcha_all_pids
  @default_formatter nil

  defstruct targets: [],
            formatter: nil,
            io_device: nil,
            limit: @default_trace_limit,
            pids: @default_trace_pids

  @type t :: %__MODULE__{
          targets: [trace_target()],
          formatter: (trace_event() -> binary()),
          io_device: atom() | pid(),
          limit: pos_integer(),
          pids: pid() | list(pid()) | :new | :existing | :all
        }

  @type trace_target :: Trace.Calls.t()

  @type trace_message :: binary
  # TODO: cover all cases in https://github.com/ferd/recon/blob/master/src/recon_trace.erl#L513
  @type trace_event ::
          {:trace, pid(), :receive, list(trace_message())}
          | {:trace, pid(), :call,
             {module :: atom, function :: atom(), arguments :: integer() | term()}}
          | {:trace, pid(), :call,
             {module :: atom, function :: atom(), arguments :: integer() | term(),
              trace_message()}}

  @doc """
  Builds a new trace.

  A custom `:formatter` function can be provided to `opts`.
  It should be a 1-arity function that accepts a `t:trace_event/0` tuple,
  and returns a message string suitable for consumption by `:io.format()`.
  """
  def new(targets, opts \\ []) do
    {formatter, opts} = Keyword.pop(opts, :formatter, &default_formatter/1)
    {io_device, opts} = Keyword.pop(opts, :io_device, :erlang.group_leader())
    {limit, opts} = Keyword.pop(opts, :limit, @default_trace_limit)
    {pids, opts} = Keyword.pop(opts, :pids, @default_trace_pids)
    _opts = opts

    %__MODULE__{
      targets: targets,
      formatter: formatter,
      io_device: io_device,
      limit: limit,
      pids: pids
    }
  end

  @doc """
  Validates a `trace`.
  """
  def validate(%__MODULE__{} = trace) do
    case do_validate_targets(trace.targets) do
      :ok -> {:ok, trace}
      {:error, target, problems} -> {:error, target, problems}
    end
  end

  defp do_validate_targets([target | rest]) do
    case Matcha.Trace.Target.validate(target) do
      {:ok, ^target} -> do_validate_targets(rest)
      {:error, problems} -> {:error, target, problems}
    end
  end

  defp do_validate_targets([]) do
    :ok
  end

  @doc """
  Validates a `trace`.
  """
  def validate!(%__MODULE__{} = trace) do
    case validate(trace) do
      {:ok, ^trace} ->
        trace

      {:error, target, problems} ->
        raise Trace.Error,
          source: trace,
          details: "when building trace target `#{inspect(target)}`",
          problems: problems
    end
  end

  ####
  # HIGH-LEVEL API
  ##

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

  @spec module(atom, keyword) :: :ignore | {:error, any} | {:ok, pid}
  @doc """
  Trace all calls to a `module`.

  By default, only #{@default_trace_limit} calls will be traced.
  More calls can be traced by providing an integer `:limit` in the `opts`.
  """
  def module(module, opts \\ [])
      when is_atom(module) and is_list(opts) do
    Trace.Calls.new(module)
    |> List.wrap()
    |> new(opts)
    |> validate!
    |> do_trace
  end

  @spec function(atom, atom, keyword) :: :ignore | {:error, any} | {:ok, pid}
  @doc """
  Trace all `function` calls to `module`.

  By default, only #{@default_trace_limit} calls will be traced.
  More calls can be traced by providing an integer `:limit` in the `opts`.
  """
  def function(module, function, opts \\ [])
      when is_atom(module) and is_atom(function) and is_list(opts) do
    Trace.Calls.new(module, function)
    |> List.wrap()
    |> new(opts)
    |> validate!
    |> do_trace
  end

  @spec calls(atom, atom, non_neg_integer | Spec.t(), keyword) :: {:ok, pid}
  @doc """
  Trace `function` calls to `module` with specified `arguments`.

  `arguments` may be:

  - an integer arity, only tracing function calls with that number of parameters
  - a `Matcha.Spec`, only tracing function calls whose arguments match the provided patterns

  If calling with just an arity, all matching calls will print a corresponding trace message.
  If calling with a spec, additional operations can be performed, as documented in `Matcha.Context.Trace`.

  By default, only #{@default_trace_limit} calls will be traced.
  More calls can be traced by providing an integer `:limit` in the `opts`.
  """
  def calls(module, function, arguments, opts \\ [])
      when is_atom(module) and is_atom(function) and
             ((is_integer(arguments) and arguments >= 0) or is_struct(arguments, Spec)) and
             is_list(opts) do
    Trace.Calls.new(module, function, arguments)
    |> List.wrap()
    |> new(opts)
    |> validate!
    |> do_trace
  end

  defp do_trace(%__MODULE__{} = trace) do
    GenServer.start_link(Trace.Tracer, trace)
  end

  ####
  # COMMANDS
  ##

  @doc """
  Starts the provided `trace` in the current process.
  """
  def start(%__MODULE__{} = trace) do
    trace_patterns =
      trace.targets
      |> Enum.flat_map(&Trace.Target.trace_patterns/1)

    trace_flags =
      trace.targets
      |> Enum.map(&Trace.Target.trace_flag/1)
      |> Enum.uniq()

    trace_pids =
      case trace.pids do
        @matcha_all_pids -> [@erlang_all_pids]
        pid when is_pid(pid) -> [pid]
        pids when is_list(pids) -> pids
      end

    for {trace_target_mfa, trace_target_specs, trace_target_flags} <- trace_patterns do
      :erlang.trace_pattern(trace_target_mfa, trace_target_specs, trace_target_flags)
    end

    for trace_pid <- trace_pids do
      :erlang.trace(trace_pid, true, trace_flags)
    end

    :ok
  end

  @doc """
  Stops all tracing for the current process.
  """
  def stop do
    :erlang.trace(:all, false, [:all])
    :erlang.trace_pattern({:_, :_, :_}, false, [:local, :meta, :call_count, :call_time])
    :erlang.trace_pattern({:_, :_, :_}, false, [])

    :ok
  end

  @doc """
  The default formatter for trace messages.
  """
  def default_formatter(trace_event)

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

  ####
  # UTILS
  ##

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
  @doc """
  Provides the `information` requested about the tracing of the specified `pid_port_func_event`.

  See [the erlang docs](https://www.erlang.org/doc/man/erlang.html#trace_info-2) for more.
  """
  def info(pid_port_func_event, information) do
    :erlang.trace_info(pid_port_func_event, information)
  end
end
