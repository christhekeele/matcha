defmodule Matcha.Trace.Tracer do
  use GenServer

  alias Matcha.Trace

  defstruct trace: nil, handler: nil, count: 0

  def new(trace = %Trace{}) do
    %__MODULE__{
      trace: trace
    }
  end

  def start_link(trace = %Trace{}) do
    GenServer.start_link(__MODULE__, new(trace))
  end

  def init(tracer) do
    {:ok, tracer, {:continue, :start}}
  end

  def handle_continue(:start, tracer = %__MODULE__{}) do
    {:ok, handler} = Trace.Handler.start_link(tracer.trace)
    tracer = %__MODULE__{tracer | handler: handler}
    :ok = Trace.start(tracer.trace)
    {:noreply, tracer}
  end

  def handle_cast(:start, tracer = %__MODULE__{}) do
    :ok = Trace.start(tracer.trace)
    {:noreply, tracer}
  end

  def handle_cast(:stop, tracer = %__MODULE__{}) do
    :ok = Trace.stop()
    {:noreply, tracer}
  end

  def handle_info({:trace, _, _, _} = trace_event, tracer = %__MODULE__{}) do
    send(tracer.handler, trace_event)

    tracer = %__MODULE__{tracer | count: tracer.count + 1}

    if is_integer(tracer.trace.limit) and tracer.count >= tracer.trace.limit do
      {:stop, :normal, tracer}
    else
      {:noreply, tracer}
    end
  end

  def terminate(:normal, tracer) do
    tracer.trace.io_device
    |> IO.puts("Tracing halted.")

    :ok = Trace.stop()
  end
end
