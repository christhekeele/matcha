defmodule Matcha.Trace.Tracer do
  @moduledoc """
  About trace tracers.

  ```mermaid
  sequenceDiagram

    participant erlang as Erlang Trace Engine
    participant Process
    participant Trace as Matcha.Trace

    Note over Process: Matcha.Trace.module(Integer)
    Process ->> Trace: Trace.start
    create participant Tracer as Matcha.Trace.Tracer
    Trace -->> Tracer: Tracer.Supervisor.start
    create participant Handler as Matcha.Trace.Handler
    Tracer -->> Handler: Handler.Supervisor.start
    create participant WorkerSupervisor as Matcha.Trace.WorkerSupervisor
    Handler -->> WorkerSupervisor: Task.Supervisor.start
    WorkerSupervisor -->> Handler: :ok
    Handler -->> Tracer: :ok
    Tracer ->> erlang: :erlang.trace(module: Integer, handler: Handler)
    Tracer -->> Trace: :ok
    Trace -->> Process: :ok

    Note over Process: Integer.parse("3")
    erlang ->> Tracer: GenServer.cast({:traced, :call, {Integer, :parse, ["3"]}})
    Tracer ->> Handler: cast({:traced, :call, {Integer, :parse, ["3"]}})
    Handler -->> WorkerSupervisor: Task.Supervisor.start_child
    create participant Worker
    WorkerSupervisor -->> Worker: Task.start
    Handler ->> Worker: Worker.handle({:traced, :call, {Integer, :parse, ["3"]}})
    Worker ->> Worker: format_message()
    destroy Worker
    Worker --x Process: IO.puts
    Note over Process: Traced call:<br />`&Integer.parse/1`<br />with arguments:<br />`["3"]`

    Note over Tracer: Limit reached
    Tracer -->> Handler: terminate
    Handler -->> WorkerSupervisor: terminate
    destroy WorkerSupervisor
    WorkerSupervisor -->> Handler: :ok
    destroy Handler
    Handler -->> Tracer: :ok
    Tracer -->> Tracer: terminate
    destroy Tracer
    Tracer -->> Tracer: :ok

    Note over Process: Integer.parse("5")
    erlang ->> Tracer: GenServer.cast({:traced, :call, {Integer, :parse, ["3"]}})
    Note over Tracer: Tracing stopped

    link Trace: Matcha.Trace @ Matcha.Trace.html
  ```

  """

  alias Matcha.Trace

  use GenServer

  defstruct [:trace, :caller, :io_device, :handler]

  @type t :: %__MODULE__{
          trace: Trace.t(),
          caller: pid() | nil,
          io_device: IO.device(),
          handler: pid()
        }

  def options(options \\ []) do
    {caller, options} = Keyword.pop(options, :caller, self())
    {io_device, options} = Keyword.pop(options, :io_device, Process.group_leader())
    {handler, options} = Keyword.pop(options, :handler)

    {[
       caller: caller,
       io_device: io_device,
       handler: handler
     ], options}
  end

  def child_spec(options) do
    {trace, options} = Keyword.pop!(options, :trace)
    {options, child_spec_options} = options(options)

    {id, child_spec_options} = Keyword.pop(child_spec_options, :id, __MODULE__)
    {restart, child_spec_options} = Keyword.pop(child_spec_options, :restart, :transient)
    {shutdown, child_spec_options} = Keyword.pop(child_spec_options, :shutdown, :brutal_kill)
    {significant, child_spec_options} = Keyword.pop(child_spec_options, :significant, false)

    extra_options = child_spec_options

    if extra_options != [] do
      problems =
        for option <- extra_options do
          {:error,
           "unexpected option `#{inspect(option)}` provided to `#{inspect(__MODULE__)}.child_spec/1`"}
        end

      raise Trace.Error,
        source: trace,
        details: "when building tracer child spec",
        problems: problems
    else
      %{
        id: id,
        start: {__MODULE__, :start_link, [[{:trace, trace} | options]]},
        type: :worker,
        restart: restart,
        shutdown: shutdown,
        significant: significant
      }
    end
  end

  def start_link(options) do
    {trace, options} = Keyword.pop!(options, :trace)
    {options, extra_options} = options(options)

    if extra_options != [] do
      problems =
        for option <- options do
          {:error,
           "unexpected option `#{inspect(option)}` provided to `#{inspect(__MODULE__)}.start_link/1`"}
        end

      raise Trace.Error, source: trace, details: "when starting tracer", problems: problems
    else
      GenServer.start_link(__MODULE__, struct!(__MODULE__, [{:trace, trace} | options]))
    end
  end

  @impl true
  def init(tracer = %__MODULE__{}) do
    if tracer.caller do
      Process.flag(:trap_exit, true)
      Process.link(tracer.caller)
    end

    tracer =
      if !tracer.handler do
        {:ok, handler} = Trace.Supervisor.start_handler(tracer, [])
        %__MODULE__{tracer | handler: handler}
      else
        tracer
      end

    {:ok, tracer, {:continue, :start_tracing}}
  end

  @impl true
  def handle_continue(:start_tracing, tracer = %__MODULE__{trace: trace = %Matcha.Trace{}}) do
    pids =
      case trace.pids do
        atom when is_atom(atom) -> [atom]
        pid when is_pid(pid) -> [pid]
        pids when is_list(pids) -> pids
      end

    Trace.Topic.trace(trace.topic, pids)

    {:noreply, tracer}
  end

  @impl true
  def handle_info(message, tracer)

  def handle_info({:EXIT, caller, _reason}, tracer = %__MODULE__{caller: caller}) do
    {:stop, :normal, tracer}
  end

  def handle_info(message, tracer = %__MODULE__{handler: handler}) do
    GenServer.cast(handler, {:__matcha_trace__, message})
    {:noreply, tracer}
  end
end
