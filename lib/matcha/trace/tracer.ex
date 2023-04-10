defmodule Matcha.Trace.Tracer do
  use GenServer

  alias Matcha.Trace

  defstruct trace: nil

  def new(trace) do
    %__MODULE__{
      trace: trace
    }
  end

  def init(trace) do
    {:ok, new(trace), {:continue, :start}}
  end

  def handle_continue(:start, tracer) do
    :ok = Trace.start(tracer.trace)
    {:noreply, tracer}
  end

  def handle_cast(:start, tracer) do
    :ok = Trace.start(tracer.trace)
    {:noreply, tracer}
  end

  def handle_cast(:stop, tracer) do
    :ok = Trace.stop()
    {:noreply, tracer}
  end

  def handle_info({:trace, _, _, _} = trace_event, tracer) do
    tracer.trace.io_device
    |> IO.puts(tracer.trace.formatter.(trace_event))

    {:noreply, tracer}
  end
end
