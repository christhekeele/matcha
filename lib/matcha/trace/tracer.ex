defmodule Matcha.Trace.Tracer do
  use GenServer

  alias Matcha.Trace

  defstruct trace: nil, count: 0

  def new(trace = %Trace{}) do
    %__MODULE__{
      trace: trace
    }
  end

  def init(trace = %Trace{}) do
    Process.flag(:trap_exit, true)
    {:ok, new(trace), {:continue, :start}}
  end

  def handle_continue(:start, tracer = %__MODULE__{}) do
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
    tracer.trace.io_device
    |> IO.puts(tracer.trace.formatter.(trace_event))

    tracer = %__MODULE__{tracer | count: tracer.count + 1}

    if tracer.count >= tracer.trace.limit do
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
